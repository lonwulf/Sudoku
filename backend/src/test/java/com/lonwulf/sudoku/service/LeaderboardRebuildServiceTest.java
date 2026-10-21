package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.constants.Constants;
import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.SliceImpl;
import org.springframework.data.domain.Sort;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.data.redis.core.ZSetOperations;

import java.time.Duration;
import java.util.List;
import java.util.Set;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anySet;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class LeaderboardRebuildServiceTest {
    private IUserRepository userRepo;
    private StringRedisTemplate redisTemplate;
    private ValueOperations<String, String> values;
    private ZSetOperations<String, String> zSet;
    private LeaderboardRebuildService rebuildService;

    @BeforeEach
    @SuppressWarnings("unchecked")
    void setUp() {
        userRepo = mock(IUserRepository.class);
        redisTemplate = mock(StringRedisTemplate.class);
        values = mock(ValueOperations.class);
        zSet = mock(ZSetOperations.class);
        when(redisTemplate.opsForValue()).thenReturn(values);
        when(redisTemplate.opsForZSet()).thenReturn(zSet);
        when(values.setIfAbsent(anyString(), anyString(), any(Duration.class))).thenReturn(true);
        rebuildService = new LeaderboardRebuildService(userRepo, redisTemplate);
    }

    @Test
    void rebuildKeepsShadowBannedUsersOffTheGlobalBoardWithoutOverwritingLiveScores() {
        User honest = new User("honest");
        honest.setLifetimeScore(50);
        Pageable first = firstPage();
        when(userRepo.findByShadowBanned(false, first)).thenReturn(new SliceImpl<>(List.of(honest), first, false));

        rebuildService.rebuildAsync(Constants.GLOBAL_LEADERBOARD);

        verify(userRepo, never()).findByShadowBanned(eq(true), any());
        verify(zSet).addIfAbsent(Constants.GLOBAL_LEADERBOARD, Set.of(ZSetOperations.TypedTuple.of("honest", 50.0)));
        verify(redisTemplate).delete(Constants.GLOBAL_LEADERBOARD + ":rebuild-lock");
    }

    @Test
    void rebuildWalksEveryPage() {
        Pageable first = firstPage();
        Pageable second = first.next();
        when(userRepo.findByShadowBanned(false, first)).thenReturn(new SliceImpl<>(List.of(new User("a")), first, true));
        when(userRepo.findByShadowBanned(false, second)).thenReturn(new SliceImpl<>(List.of(new User("b")), second, false));

        rebuildService.rebuildAsync(Constants.GLOBAL_LEADERBOARD);

        verify(zSet).addIfAbsent(Constants.GLOBAL_LEADERBOARD, Set.of(ZSetOperations.TypedTuple.of("a", 0.0)));
        verify(zSet).addIfAbsent(Constants.GLOBAL_LEADERBOARD, Set.of(ZSetOperations.TypedTuple.of("b", 0.0)));
    }

    @Test
    void rebuildSkipsRedisWhenThereIsNobodyToAdd() {
        Pageable first = firstPage();
        when(userRepo.findByShadowBanned(true, first)).thenReturn(new SliceImpl<>(List.of(), first, false));

        rebuildService.rebuildAsync(Constants.SHADOW_LEADERBOARD);

        verify(zSet, never()).addIfAbsent(any(), anySet());
    }

    @Test
    void anotherInstanceHoldingTheLockSkipsTheRebuild() {
        when(values.setIfAbsent(anyString(), anyString(), any(Duration.class))).thenReturn(false);

        rebuildService.rebuildAsync(Constants.GLOBAL_LEADERBOARD);

        verify(userRepo, never()).findByShadowBanned(anyBoolean(), any());
        verify(redisTemplate, never()).delete(anyString());
    }

    private Pageable firstPage() {
        return PageRequest.of(0, LeaderboardRebuildService.PAGE_SIZE, Sort.by("id"));
    }
}
