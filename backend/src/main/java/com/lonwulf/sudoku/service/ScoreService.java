package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.constants.Constants;
import com.lonwulf.sudoku.data.dto.LeaderboardEntryDTO;
import com.lonwulf.sudoku.data.dto.LeaderboardResponseDTO;
import com.lonwulf.sudoku.data.dto.ScoreResponseDTO;
import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import org.springframework.data.redis.core.RedisCallback;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
public class ScoreService {
    private final StringRedisTemplate redisTemplate;
    private final IUserRepository userRepo;
    private final LeaderboardRebuildService rebuildService;

    // per-user backoff while a board is being rebuilt; cleared once they get a ready response
    private final Map<String, Integer> retryTracker = new ConcurrentHashMap<>();

    public ScoreService(IUserRepository userRepo,
                        StringRedisTemplate redisTemplate,
                        LeaderboardRebuildService rebuildService) {
        this.userRepo = userRepo;
        this.redisTemplate = redisTemplate;
        this.rebuildService = rebuildService;
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

    @Transactional
    public ScoreResponseDTO recordCompletion(User user, int pointsEarned) {
        user.incrementPuzzlesCompleted();
        user.addScore(pointsEarned);
        userRepo.save(user);

        // Update Redis leaderboard, then read back rank
        String leaderboardKey = getLeaderboardKey(user);
        Double totalScore = redisTemplate.opsForZSet().incrementScore(leaderboardKey, user.getId(), pointsEarned);
        Long rank = redisTemplate.opsForZSet().reverseRank(leaderboardKey, user.getId());

        return new ScoreResponseDTO(
                user.getId(),
                user.getDisplayName(),
                user.getPuzzlesCompleted(),
                totalScore != null ? totalScore.intValue() : 0,
                rank != null ? rank + 1 : null
        );
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
