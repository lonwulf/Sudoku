package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.constants.Constants;
import com.lonwulf.sudoku.data.dto.CompletionResponseDTO;
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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class ScoreService {
    private final StringRedisTemplate redisTemplate;
    private final IUserScoreRepository userScoreRepo;
    private final IUserRepository userRepo;

    public ScoreService(IUserScoreRepository userScoreRepo,
                        IUserRepository userRepo,
                        StringRedisTemplate redisTemplate) {
        this.userScoreRepo = userScoreRepo;
        this.userRepo = userRepo;
        this.redisTemplate = redisTemplate;
    }

    private String getLeaderboardKey(User user) {
        return user.isShadowBanned() ? Constants.SHADOW_LEADERBOARD : Constants.GLOBAL_LEADERBOARD;
    }

    @Transactional
    public CompletionResponseDTO recordCompletion(String userId, String email, String displayName) {
        String safeName = (displayName != null && !displayName.isBlank()) ? displayName : "Anonymous";
        String safeEmail = (email != null && !email.isBlank()) ? email : "unknown@example.com";

        // Upsert User entity
        User user = userRepo.findById(userId).orElseGet(() -> {
            User u = new User();
            u.setId(userId);
            u.setLifetimeScore(0);
            u.setPuzzlesCompleted(0);
            return u;
        });
        user.setDisplayName(safeName);
        user.setEmail(safeEmail);
        user.incrementPuzzlesCompleted();
        userRepo.save(user);

        // Upsert UserScore entity
        UserScore score = userScoreRepo.findByUserId(userId)
                .orElseGet(() -> new UserScore(userId));
        score.increment();
        userScoreRepo.save(score);

        // Update Redis leaderboard
        redisTemplate.opsForZSet().incrementScore(getLeaderboardKey(user), userId, 1);

        return new CompletionResponseDTO(userId, score.getPuzzlesCompleted());
    }


    public int getCompletedCount(String userId) {
        return userScoreRepo.findByUserId(userId)
                .map(UserScore::getPuzzlesCompleted)
                .orElse(0);
    }

    @Transactional
    public ScoreResponseDTO submitScore(String userId, int pointsEarned, boolean completed) {
        User user = userRepo.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        // Update Redis leaderboard
        redisTemplate.opsForZSet().incrementScore(getLeaderboardKey(user), userId, pointsEarned);

        // Update SQL score
        UserScore userScore = userScoreRepo.findByUserId(userId)
                .orElse(new UserScore(userId));
        userScore.setTotalPoints(userScore.getTotalPoints() + pointsEarned);

        if (completed) user.incrementPuzzlesCompleted();
        userScore.setLastUpdated(LocalDateTime.now());
        userScoreRepo.save(userScore);

        // Get updated rank + score
        Long rank = redisTemplate.opsForZSet().reverseRank(getLeaderboardKey(user), userId);
        Double totalScore = redisTemplate.opsForZSet().score(getLeaderboardKey(user), userId);

        return new ScoreResponseDTO(
                userId,
                user.getDisplayName(),
                user.getPuzzlesCompleted(),
                totalScore != null ? totalScore.intValue() : 0,
                rank != null ? rank + 1 : null
        );
    }


    @SuppressWarnings("unchecked")
    public LeaderboardResponseDTO getLeaderboardData(String userId, int page, int size, int window) {
        Long start = (long) page * size;
        Long end = start + size - 1;
        int nearbyFetch = window * 2 + 1;

        User user = userRepo.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        List<Object> pipelineResults = redisTemplate.executePipelined((RedisCallback<Object>) connection -> {

            byte[] key = redisTemplate.getStringSerializer().serialize(getLeaderboardKey(user));
            byte[] userKey = redisTemplate.getStringSerializer().serialize(userId);

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
            return new LeaderboardResponseDTO(List.of(), null, List.of());
        }

        long from = Math.max(0, myRanking - window);
        long to = Math.min(bigSlice.size() - 1, myRanking + window);
        List<ZSetOperations.TypedTuple<String>> nearbyData =
                new ArrayList<>(bigSlice).subList((int) from, (int) (to + 1));

        // Collect user info
        Set<String> allIds = new HashSet<>();
        if (globalData != null) globalData.forEach(t -> allIds.add(t.getValue()));
        nearbyData.forEach(t -> allIds.add(t.getValue()));
        allIds.add(userId);

        Map<String, User> users = userRepo.findAllById(allIds).stream()
                .collect(Collectors.toMap(User::getId, u -> u));

        List<LeaderboardEntryDTO> global = mapLeaderboard(globalData != null ? globalData : Set.of(), users, start);
        LeaderboardEntryDTO me = new LeaderboardEntryDTO(
                myRanking + 1,
                userId,
                users.getOrDefault(userId, new User(userId)).getDisplayName(),
                myScore.intValue()
        );
        List<LeaderboardEntryDTO> nearby = mapLeaderboard(new LinkedHashSet<>(nearbyData), users, from);

        return new LeaderboardResponseDTO(global, me, nearby);
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
