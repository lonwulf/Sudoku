package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.constants.Constants;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * Repopulates a Redis leaderboard from the database.
 * Kept separate from ScoreService so calls go through the @Async proxy (self-invocation would run inline).
 */
@Service
public class LeaderboardRebuildService {
    private static final Logger log = LoggerFactory.getLogger(LeaderboardRebuildService.class);

    private final IUserRepository userRepo;
    private final StringRedisTemplate redisTemplate;

    private final Map<String, Boolean> rebuildInProgress = new ConcurrentHashMap<>();

    public LeaderboardRebuildService(IUserRepository userRepo, StringRedisTemplate redisTemplate) {
        this.userRepo = userRepo;
        this.redisTemplate = redisTemplate;
    }

    @Async
    public void rebuildAsync(String leaderboardKey) {
        if (rebuildInProgress.putIfAbsent(leaderboardKey, true) != null) {
            return; //someone already building, skip
        }
        try {
            rebuild(leaderboardKey);
        } finally {
            rebuildInProgress.remove(leaderboardKey);
        }
    }

    void rebuild(String leaderboardKey) {
        try {
            // shadow-banned users only ever belong on the shadow board
            boolean shadowBanned = Constants.SHADOW_LEADERBOARD.equals(leaderboardKey);
            Set<ZSetOperations.TypedTuple<String>> entries = userRepo.findByShadowBanned(shadowBanned).stream()
                    .map(u -> ZSetOperations.TypedTuple.of(u.getId(), (double) u.getLifetimeScore()))
                    .collect(Collectors.toSet());
            if (!entries.isEmpty()) {
                redisTemplate.opsForZSet().add(leaderboardKey, entries); // single ZADD
            }
            log.info("Leaderboard {} rebuilt with {} entries", leaderboardKey, entries.size());
        } catch (Exception e) {
            log.error("Leaderboard {} rebuild failed", leaderboardKey, e);
        }
    }
}
