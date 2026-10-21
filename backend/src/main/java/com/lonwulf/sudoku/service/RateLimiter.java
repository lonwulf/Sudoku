package com.lonwulf.sudoku.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.RedisScript;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.util.List;

/**
 * Fixed one-minute window counter in Redis, so the limit holds across every backend instance.
 */
@Service
public class RateLimiter {
    private static final Logger log = LoggerFactory.getLogger(RateLimiter.class);
    public static final String KEY_PREFIX = "sudoku:ratelimit:";
    private static final long WINDOW_MILLIS = 60_000;

    // INCR and set the TTL atomically; the TTL only cleans up, since the window is part of the key
    private static final RedisScript<Long> INCREMENT = RedisScript.of("""
            local count = redis.call('INCR', KEYS[1])
            if count == 1 then redis.call('PEXPIRE', KEYS[1], ARGV[1]) end
            return count""", Long.class);

    private final StringRedisTemplate redisTemplate;
    private final Clock clock;

    @Autowired
    public RateLimiter(StringRedisTemplate redisTemplate) {
        this(redisTemplate, Clock.systemUTC());
    }

    // for tests
    RateLimiter(StringRedisTemplate redisTemplate, Clock clock) {
        this.redisTemplate = redisTemplate;
        this.clock = clock;
    }

    /**
     * @return 0 if the request is allowed, otherwise the seconds until the client may retry
     */
    public long tryAcquire(String bucket, String client, int limitPerMinute) {
        long now = clock.millis();
        long window = now / WINDOW_MILLIS;
        String key = KEY_PREFIX + bucket + ":" + client + ":" + window;
        try {
            Long count = redisTemplate.execute(INCREMENT, List.of(key), String.valueOf(WINDOW_MILLIS));
            if (count == null || count <= limitPerMinute) return 0;
        } catch (Exception e) {
            // fail open: an unreachable Redis shouldn't turn into a rate-limit outage
            log.warn("Rate limiter unavailable, allowing request: {}", e.getMessage());
            return 0;
        }
        long windowEnd = (window + 1) * WINDOW_MILLIS;
        return Math.max(1, (windowEnd - now + 999) / 1000);
    }
}
