package com.lonwulf.sudoku.service;

import org.junit.jupiter.api.Test;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.RedisScript;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class RateLimiterTest {
    // 45s into a minute window
    private final Clock clock = Clock.fixed(Instant.ofEpochMilli(60_000L * 1000 + 45_000), ZoneOffset.UTC);
    private final StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
    private final RateLimiter rateLimiter = new RateLimiter(redisTemplate, clock);
    private final List<String> key = List.of(RateLimiter.KEY_PREFIX + "puzzle:ip:1.2.3.4:1000");

    @Test
    @SuppressWarnings("unchecked")
    void allowsUpToTheLimitThenReportsSecondsUntilTheWindowEnds() {
        when(redisTemplate.execute(any(RedisScript.class), eq(key), anyString())).thenReturn(30L, 31L);

        assertEquals(0, rateLimiter.tryAcquire("puzzle", "ip:1.2.3.4", 30));
        assertEquals(15, rateLimiter.tryAcquire("puzzle", "ip:1.2.3.4", 30));
    }

    @Test
    @SuppressWarnings("unchecked")
    void failsOpenWhenRedisIsDown() {
        when(redisTemplate.execute(any(RedisScript.class), eq(key), anyString()))
                .thenThrow(new RedisConnectionFailureException("down"));

        assertEquals(0, rateLimiter.tryAcquire("puzzle", "ip:1.2.3.4", 30));
    }
}
