package com.lonwulf.sudoku.service;

import org.junit.jupiter.api.Test;
import org.springframework.data.redis.core.HashOperations;
import org.springframework.data.redis.core.StringRedisTemplate;

import java.time.Duration;

import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class SudokuCacheServiceTest {

    @Test
    @SuppressWarnings("unchecked")
    void puzzlesExpireAfterTheConfiguredTtl() {
        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        HashOperations<String, Object, Object> hashes = mock(HashOperations.class);
        when(redisTemplate.<Object, Object>opsForHash()).thenReturn(hashes);
        SudokuCacheService cache = new SudokuCacheService(redisTemplate, Duration.ofHours(24));

        cache.savePuzzle("p1", "hard", new int[9][9]);

        verify(hashes).putAll(eq(SudokuCacheService.PUZZLE_KEY_PREFIX + "p1"), anyMap());
        verify(redisTemplate).expire(SudokuCacheService.PUZZLE_KEY_PREFIX + "p1", Duration.ofHours(24));
    }
}
