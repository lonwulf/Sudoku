package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.constants.Constants;
import com.lonwulf.sudoku.data.dto.LeaderboardEntryDTO;
import com.lonwulf.sudoku.data.dto.LeaderboardResponseDTO;
import com.lonwulf.sudoku.data.dto.ScoreResponseDTO;
import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.data.redis.core.RedisCallback;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
public class ScoreService {
    private static final Logger log = LoggerFactory.getLogger(ScoreService.class);

    private final StringRedisTemplate redisTemplate;
    private final IUserRepository userRepo;
    private final LeaderboardRebuildService rebuildService;
    private final TransactionTemplate transactionTemplate;

    // per-user backoff while a board is being rebuilt; cleared once they get a ready response
    private final Map<String, Integer> retryTracker = new ConcurrentHashMap<>();

    public ScoreService(IUserRepository userRepo,
                        StringRedisTemplate redisTemplate,
                        LeaderboardRebuildService rebuildService,
                        TransactionTemplate transactionTemplate) {
        this.userRepo = userRepo;
        this.redisTemplate = redisTemplate;
        this.rebuildService = rebuildService;
        this.transactionTemplate = transactionTemplate;
    }

    private String getLeaderboardKey(User user) {
        return user.isShadowBanned() ? Constants.SHADOW_LEADERBOARD : Constants.GLOBAL_LEADERBOARD;
    }

    // Points are decided here, never by the client
    public static int pointsForDifficulty(String difficulty) {
        return switch (difficulty) {
            case "easy" -> 10;
            case "hard" -> 30;
            default -> 20; //medium
        };
    }

    public ScoreResponseDTO recordCompletion(User user, int pointsEarned) {
        // Commit the points first and only then touch Redis: a Redis failure can leave the board
        // behind the database (the source of truth), but never holding points the database lacks
        User updated = transactionTemplate.execute(status -> {
            userRepo.addCompletion(user.getId(), pointsEarned);
            return userRepo.findById(user.getId()).orElseThrow();
        });

        String leaderboardKey = getLeaderboardKey(updated);
        Double totalScore = null;
        Long rank = null;
        try {
            totalScore = redisTemplate.opsForZSet().incrementScore(leaderboardKey, updated.getId(), pointsEarned);
            rank = redisTemplate.opsForZSet().reverseRank(leaderboardKey, updated.getId());
        } catch (DataAccessException e) {
            log.error("Leaderboard update failed for {}; points are saved but the board lags", updated.getId(), e);
        }

        return new ScoreResponseDTO(
                updated.getId(),
                updated.getDisplayName(),
                updated.getPuzzlesCompleted(),
                totalScore != null ? totalScore.intValue() : updated.getLifetimeScore(),
                rank != null ? rank + 1 : null
        );
    }

    // The score comes from the database (the source of truth); the rank is best effort and null
    // when Redis is down or the player isn't on the board yet
    public ScoreResponseDTO getStanding(User user) {
        Long rank = null;
        try {
            rank = redisTemplate.opsForZSet().reverseRank(getLeaderboardKey(user), user.getId());
        } catch (DataAccessException e) {
            log.warn("Rank lookup failed for {}: {}", user.getId(), e.getMessage());
        }
        return new ScoreResponseDTO(
                user.getId(),
                user.getDisplayName(),
                user.getPuzzlesCompleted(),
                user.getLifetimeScore(),
                rank != null ? rank + 1 : null
        );
    }

    // An empty board is either new or lost from Redis; only the database can tell which
    private boolean anyoneHasScored(User user) {
        return userRepo.existsByShadowBannedAndLifetimeScoreGreaterThan(user.isShadowBanned(), 0);
    }

    private boolean isRedisPopulated(String leaderboardKey) {
        Long size = redisTemplate.opsForZSet().size(leaderboardKey);
        return size != null && size > 0;
    }

    private int computeRetryAfter(String userId){
        int current = retryTracker.getOrDefault(userId, 1);
        int next = Math.min(current * 2, 60);
        retryTracker.put(userId, next);
        return current;
    }

    @SuppressWarnings("unchecked")
    public LeaderboardResponseDTO getLeaderboardData(User user, int page, int size, int window) {
        Long start = (long) page * size;
        Long end = start + size - 1;
        String leaderboardKey = getLeaderboardKey(user);

        boolean redisReady = isRedisPopulated(leaderboardKey);
        if (!redisReady && !anyoneHasScored(user)) {
            // nothing to rebuild: the board is genuinely empty
            retryTracker.remove(user.getId());
            return LeaderboardResponseDTO.ready(List.of(), null, List.of());
        }
        if (!redisReady){
            int retryAfter = computeRetryAfter(user.getId());
            rebuildService.rebuildAsync(leaderboardKey);
            return LeaderboardResponseDTO.initializing(retryAfter);
        }

        List<Object> pipelineResults = redisTemplate.executePipelined((RedisCallback<Object>) connection -> {

            byte[] key = redisTemplate.getStringSerializer().serialize(leaderboardKey);
            byte[] userKey = redisTemplate.getStringSerializer().serialize(user.getId());

            connection.zRevRangeWithScores(key, start, end); // global
            connection.zRevRank(key, userKey);               // rank
            connection.zScore(key, userKey);                 // score

            return null;
        });

        Set<ZSetOperations.TypedTuple<String>> globalData =
                (Set<ZSetOperations.TypedTuple<String>>) pipelineResults.get(0);

        Long myRanking = (Long) pipelineResults.get(1);
        Double myScore = (Double) pipelineResults.get(2);

        retryTracker.remove(user.getId());

        // players around my own rank, wherever that is on the board;
        // a user who hasn't scored since the board was built is simply unranked (me = null, no nearby)
        boolean ranked = myRanking != null && myScore != null;
        long from = ranked ? Math.max(0, myRanking - window) : 0;
        Set<ZSetOperations.TypedTuple<String>> nearbyData = ranked
                ? redisTemplate.opsForZSet().reverseRangeWithScores(leaderboardKey, from, myRanking + window)
                : null;
        if (nearbyData == null) nearbyData = Set.of();

        // Collect user info
        Set<String> allIds = new HashSet<>();
        if (globalData != null) globalData.forEach(t -> allIds.add(t.getValue()));
        nearbyData.forEach(t -> allIds.add(t.getValue()));
        allIds.add(user.getId());

        Map<String, User> users = userRepo.findAllById(allIds).stream()
                .collect(Collectors.toMap(User::getId, u -> u));

        List<LeaderboardEntryDTO> global = mapLeaderboard(globalData != null ? globalData : Set.of(), users, start);
        LeaderboardEntryDTO me = ranked ? new LeaderboardEntryDTO(
                myRanking + 1,
                user.getId(),
                user.getDisplayName(),
                myScore.intValue()
        ) : null;
        List<LeaderboardEntryDTO> nearby = mapLeaderboard(nearbyData, users, from);

        return LeaderboardResponseDTO.ready(global, me, nearby);
    }

    private List<LeaderboardEntryDTO> mapLeaderboard(
            Set<ZSetOperations.TypedTuple<String>> data,
            Map<String, User> users,
            long offset
    ) {
        List<LeaderboardEntryDTO> result = new ArrayList<>();
        int index = 0;
        for (ZSetOperations.TypedTuple<String> tuple : data) {
            String uId = tuple.getValue();
            User user = users.get(uId);
            result.add(new LeaderboardEntryDTO(
                    offset + index + 1,
                    uId,
                    user != null ? user.getDisplayName() : "Unknown",
                    tuple.getScore().intValue()
            ));
            index++;
        }
        return result;
    }
}
