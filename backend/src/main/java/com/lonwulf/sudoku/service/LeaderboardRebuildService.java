package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.constants.Constants;
import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.domain.Sort;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Repopulates a Redis leaderboard from the database.
 * Kept separate from ScoreService so calls go through the @Async proxy (self-invocation would run inline).
 */
@Service
public class LeaderboardRebuildService {
    private static final Logger log = LoggerFactory.getLogger(LeaderboardRebuildService.class);
    static final int PAGE_SIZE = 1000;
    // outlives any realistic rebuild, but frees the lock if an instance dies mid-rebuild
    private static final Duration LOCK_TTL = Duration.ofMinutes(5);

    private final IUserRepository userRepo;
    private final StringRedisTemplate redisTemplate;

    public LeaderboardRebuildService(IUserRepository userRepo, StringRedisTemplate redisTemplate) {
        this.userRepo = userRepo;
        this.redisTemplate = redisTemplate;
    }

    @Async
    public void rebuildAsync(String leaderboardKey) {
        // a Redis lock, so only one instance rebuilds a board at a time
        String lockKey = leaderboardKey + ":rebuild-lock";
        try {
            if (!Boolean.TRUE.equals(redisTemplate.opsForValue().setIfAbsent(lockKey, "1", LOCK_TTL))) {
                return; //someone already building, skip
            }
            try {
                rebuild(leaderboardKey);
            } finally {
                redisTemplate.delete(lockKey);
            }
        } catch (Exception e) {
            log.error("Leaderboard {} rebuild failed", leaderboardKey, e);
        }
    }

    private void rebuild(String leaderboardKey) {
        // shadow-banned users only ever belong on the shadow board, and players without points
        // on neither: completions are what put a player on a board
        boolean shadowBanned = Constants.SHADOW_LEADERBOARD.equals(leaderboardKey);
        Pageable page = PageRequest.of(0, PAGE_SIZE, Sort.by("id"));
        long total = 0;
        Slice<User> slice;
        do {
            slice = userRepo.findByShadowBannedAndLifetimeScoreGreaterThan(shadowBanned, 0, page);
            Set<ZSetOperations.TypedTuple<String>> entries = slice.stream()
                    .map(u -> ZSetOperations.TypedTuple.of(u.getId(), (double) u.getLifetimeScore()))
                    .collect(Collectors.toSet());
            if (!entries.isEmpty()) {
                // one ZADD NX per page: never overwrite a score that was incremented while we rebuilt
                redisTemplate.opsForZSet().addIfAbsent(leaderboardKey, entries);
                total += entries.size();
            }
            page = slice.nextPageable();
        } while (slice.hasNext());
        log.info("Leaderboard {} rebuilt with {} entries", leaderboardKey, total);
    }
}
