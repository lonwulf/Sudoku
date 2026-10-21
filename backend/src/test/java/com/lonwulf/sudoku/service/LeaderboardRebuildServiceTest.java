package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.constants.Constants;
import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;

import java.util.List;
import java.util.Set;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anySet;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class LeaderboardRebuildServiceTest {
    private IUserRepository userRepo;
    private ZSetOperations<String, String> zSet;
    private LeaderboardRebuildService rebuildService;

    @BeforeEach
    @SuppressWarnings("unchecked")
    void setUp() {
        userRepo = mock(IUserRepository.class);
        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        zSet = mock(ZSetOperations.class);
        when(redisTemplate.opsForZSet()).thenReturn(zSet);
        rebuildService = new LeaderboardRebuildService(userRepo, redisTemplate);
    }

    @Test
    void rebuildKeepsShadowBannedUsersOffTheGlobalBoard() {
        User honest = new User("honest");
        honest.setLifetimeScore(50);
        when(userRepo.findByShadowBanned(false)).thenReturn(List.of(honest));

        rebuildService.rebuildAsync(Constants.GLOBAL_LEADERBOARD);

        verify(userRepo, never()).findByShadowBanned(true);
        verify(zSet).add(eq(Constants.GLOBAL_LEADERBOARD),
                eq(Set.of(ZSetOperations.TypedTuple.of("honest", 50.0))));
    }

    @Test
    void rebuildSkipsRedisWhenThereIsNobodyToAdd() {
        when(userRepo.findByShadowBanned(true)).thenReturn(List.of());

        rebuildService.rebuildAsync(Constants.SHADOW_LEADERBOARD);

        verify(zSet, never()).add(any(), anySet());
    }
}
