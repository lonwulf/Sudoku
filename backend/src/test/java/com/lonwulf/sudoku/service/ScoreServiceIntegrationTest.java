package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.data.dto.ScoreResponseDTO;
import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

// Redis is pointed at a closed port, so this is the "Redis fails after the DB commit" case even
// when a dev Redis is running on the default port
@SpringBootTest(properties = "spring.data.redis.port=1")
class ScoreServiceIntegrationTest {
    @Autowired
    private ScoreService scoreService;
    @Autowired
    private IUserRepository userRepository;

    @Test
    void concurrentCompletionsAreAllCountedAndSurviveARedisFailure() throws Exception {
        User user = userRepository.saveAndFlush(new User("carol"));
        int threads = 8;
        CountDownLatch go = new CountDownLatch(1);
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        List<ScoreResponseDTO> responses = new ArrayList<>();
        try {
            List<Future<ScoreResponseDTO>> results = new ArrayList<>();
            for (int i = 0; i < threads; i++) {
                results.add(pool.submit(() -> {
                    go.await();
                    return scoreService.recordCompletion(user, 10);
                }));
            }
            go.countDown();
            for (Future<ScoreResponseDTO> result : results) responses.add(result.get(60, TimeUnit.SECONDS));
        } finally {
            pool.shutdownNow();
        }

        User saved = userRepository.findById("carol").orElseThrow();
        assertEquals(threads, saved.getPuzzlesCompleted());
        assertEquals(threads * 10, saved.getLifetimeScore());
        for (ScoreResponseDTO response : responses) {
            assertNull(response.rank()); // board unavailable
            assertTrue(response.leaderboardScore() >= 10); // falls back to the committed DB score
        }
    }
}
