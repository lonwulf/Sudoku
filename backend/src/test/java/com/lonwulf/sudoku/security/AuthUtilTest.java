package com.lonwulf.sudoku.security;

import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

@SpringBootTest
class AuthUtilTest {
    @Autowired
    private AuthUtil authUtil;
    @Autowired
    private IUserRepository userRepository;

    @Test
    void newUserWithExistingIdFailsInsteadOfOverwritingScores() {
        User existing = new User("alice");
        existing.setLifetimeScore(50);
        userRepository.saveAndFlush(existing);

        assertThrows(DataIntegrityViolationException.class, () -> userRepository.saveAndFlush(new User("alice")));
        assertEquals(50, userRepository.findById("alice").orElseThrow().getLifetimeScore());
    }

    @Test
    void concurrentFirstRequestsAllResolveToOneUser() throws Exception {
        Authentication auth = new UsernamePasswordAuthenticationToken("bob", null, List.of());
        int threads = 8;
        CountDownLatch go = new CountDownLatch(1);
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        try {
            List<Future<User>> results = new ArrayList<>();
            for (int i = 0; i < threads; i++) {
                results.add(pool.submit(() -> {
                    go.await(); // release all first requests at once
                    return authUtil.ensureUserExists(auth);
                }));
            }
            go.countDown();
            for (Future<User> result : results) {
                assertEquals("bob", result.get(30, TimeUnit.SECONDS).getId());
            }
        } finally {
            pool.shutdownNow();
        }
        assertEquals(1, userRepository.findAllById(List.of("bob")).size());
    }
}
