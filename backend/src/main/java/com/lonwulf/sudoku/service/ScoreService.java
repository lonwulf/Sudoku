package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.constants.Constants;
import com.lonwulf.sudoku.data.dto.LeaderboardEntryDTO;
import com.lonwulf.sudoku.data.dto.LeaderboardResponseDTO;
import com.lonwulf.sudoku.data.dto.ScoreResponseDTO;
import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.data.entity.UserScore;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import com.lonwulf.sudoku.data.repository.IUserScoreRepository;
import org.springframework.data.redis.core.RedisCallback;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
public class ScoreService {
    private final StringRedisTemplate redisTemplate;
    private final IUserScoreRepository userScoreRepo;
    private final IUserRepository userRepo;

    private final Map<String, Boolean> rebuildInProgress = new ConcurrentHashMap<>();
    private final Map<String, Integer> retryTracker = new ConcurrentHashMap<>();

    public ScoreService(IUserScoreRepository userScoreRepo,
                        IUserRepository userRepo,
                        StringRedisTemplate redisTemplate) {
        this.userScoreRepo = userScoreRepo;
        this.userRepo = userRepo;
        this.redisTemplate = redisTemplate;
    }

    public void triggerAsyncRebuild(String leaderboardKey){
        if (Boolean.TRUE.equals(rebuildInProgress.putIfAbsent(leaderboardKey, true))){
            //someone already building, skip
            return;
        }
        rebuildLeaderboard(leaderboardKey);
    }

    @Async
    public void rebuildLeaderboard(String leaderboardKey){
        try{
           List<UserScore> allScores = userScoreRepo.findAll();
           for (UserScore score : allScores){
               redisTemplate.opsForZSet()
                       .add(leaderboardKey, score.getUserId(), score.getTotalPoints());
           }
           System.out.println("Leaderboard rebuild complete");
        } catch (Exception e) {
            System.err.println("Leaderboard rebuild failed" + e.getMessage());
        } finally {
            rebuildInProgress.remove(leaderboardKey);
        }
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

        // Upsert UserScore entity
        UserScore userScore = userScoreRepo.findByUserId(user.getId())
                .orElseGet(() -> new UserScore(user.getId()));
        userScore.increment();
        userScore.setTotalPoints(userScore.getTotalPoints() + pointsEarned);
        userScore.setLastUpdated(LocalDateTime.now());
        userScoreRepo.save(userScore);

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

    public int getCompletedCount(String userId) {
        return userScoreRepo.findByUserId(userId)
                .map(UserScore::getPuzzlesCompleted)
                .orElse(0);
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
        int nearbyFetch = window * 2 + 1;

        boolean redisReady = isRedisPopulated(getLeaderboardKey(user));
        if (!redisReady){
            int retryAfter = computeRetryAfter(user.getId());
            triggerAsyncRebuild(getLeaderboardKey(user));
            return LeaderboardResponseDTO.initializing(retryAfter);
        }

        List<Object> pipelineResults = redisTemplate.executePipelined((RedisCallback<Object>) connection -> {

            byte[] key = redisTemplate.getStringSerializer().serialize(getLeaderboardKey(user));
            byte[] userKey = redisTemplate.getStringSerializer().serialize(user.getId());

            connection.zRevRangeWithScores(key, start, end); // global
            connection.zRevRank(key, userKey);               // rank
            connection.zScore(key, userKey);                 // score
            connection.zRevRangeWithScores(key, 0, start + size + nearbyFetch); // nearby slice

            return null;
        });

        Set<ZSetOperations.TypedTuple<String>> globalData =
                (Set<ZSetOperations.TypedTuple<String>>) pipelineResults.get(0);

        Long myRanking = (Long) pipelineResults.get(1);
        Double myScore = (Double) pipelineResults.get(2);

        Set<ZSetOperations.TypedTuple<String>> bigSlice =
                (Set<ZSetOperations.TypedTuple<String>>) pipelineResults.get(3);

        if (myRanking == null || myScore == null) {
            return LeaderboardResponseDTO.initializing(computeRetryAfter(user.getId()));
        }

        long from = Math.max(0, myRanking - window);
        long to = Math.min(bigSlice.size() - 1, myRanking + window);
        List<ZSetOperations.TypedTuple<String>> nearbyData =
                new ArrayList<>(bigSlice).subList((int) from, (int) (to + 1));

        // Collect user info
        Set<String> allIds = new HashSet<>();
        if (globalData != null) globalData.forEach(t -> allIds.add(t.getValue()));
        nearbyData.forEach(t -> allIds.add(t.getValue()));
        allIds.add(user.getId());

        Map<String, User> users = userRepo.findAllById(allIds).stream()
                .collect(Collectors.toMap(User::getId, u -> u));

        List<LeaderboardEntryDTO> global = mapLeaderboard(globalData != null ? globalData : Set.of(), users, start);
        LeaderboardEntryDTO me = new LeaderboardEntryDTO(
                myRanking + 1,
                user.getId(),
                user.getDisplayName(),
                myScore.intValue()
        );
        List<LeaderboardEntryDTO> nearby = mapLeaderboard(new LinkedHashSet<>(nearbyData), users, from);

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

    public void unbanUser(String userId, String adminName) {
        User user = userRepo.findById(userId).orElseThrow();
        if (!user.isShadowBanned()) return;

        Double score = redisTemplate.opsForZSet()
                .score(Constants.SHADOW_LEADERBOARD, userId);

        if (score != null) {
            redisTemplate.opsForZSet()
                    .remove(Constants.SHADOW_LEADERBOARD, userId);
            redisTemplate.opsForZSet()
                    .add(Constants.GLOBAL_LEADERBOARD, userId, score);
        }
        user.setShadowBanned(false);
        userRepo.save(user);
    }
}
