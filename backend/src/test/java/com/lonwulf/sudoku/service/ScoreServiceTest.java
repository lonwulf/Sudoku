package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.constants.Constants;
import com.lonwulf.sudoku.data.dto.LeaderboardEntryDTO;
import com.lonwulf.sudoku.data.dto.LeaderboardResponseDTO;
import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.redis.core.RedisCallback;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anySet;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ScoreServiceTest {
    private IUserRepository userRepo;
    private StringRedisTemplate redisTemplate;
    private ZSetOperations<String, String> zSet;
    private ScoreService scoreService;

    @BeforeEach
    @SuppressWarnings("unchecked")
    void setUp() {
        userRepo = mock(IUserRepository.class);
        redisTemplate = mock(StringRedisTemplate.class);
        zSet = mock(ZSetOperations.class);
        when(redisTemplate.opsForZSet()).thenReturn(zSet);
        when(zSet.size(Constants.GLOBAL_LEADERBOARD)).thenReturn(1000L);
        when(userRepo.findAllById(any())).thenReturn(List.of());
        scoreService = new ScoreService(userRepo, redisTemplate);
    }

    @Test
    void nearbyIsCenteredOnUserRankedBelowThePage() {
        // rank index 499 used to make subList(497, 13) throw
        User me = new User("me");
        stubPipeline(499L, 42.0);
        when(zSet.reverseRangeWithScores(Constants.GLOBAL_LEADERBOARD, 497, 501))
                .thenReturn(tuples("a", "b", "me", "c", "d"));

        LeaderboardResponseDTO response = scoreService.getLeaderboardData(me, 0, 10, 2);

        assertEquals("ready", response.state());
        assertEquals(500, response.me().rank());
        assertEquals(List.of(498L, 499L, 500L, 501L, 502L),
                response.nearby().stream().map(LeaderboardEntryDTO::rank).toList());
        assertEquals("me", response.nearby().get(2).userId());
    }

    @Test
    void nearbyStartsAtTopForLeader() {
        User me = new User("me");
        stubPipeline(0L, 99.0);
        when(zSet.reverseRangeWithScores(Constants.GLOBAL_LEADERBOARD, 0, 2))
                .thenReturn(tuples("me", "a", "b"));

        LeaderboardResponseDTO response = scoreService.getLeaderboardData(me, 0, 10, 2);

        assertEquals(List.of(1L, 2L, 3L),
                response.nearby().stream().map(LeaderboardEntryDTO::rank).toList());
    }

    @Test
    void rebuildKeepsShadowBannedUsersOffTheGlobalBoard() {
        User honest = new User("honest");
        honest.setLifetimeScore(50);
        when(userRepo.findByShadowBanned(false)).thenReturn(List.of(honest));

        scoreService.rebuildLeaderboard(Constants.GLOBAL_LEADERBOARD);

        verify(userRepo, never()).findByShadowBanned(true);
        verify(zSet).add(eq(Constants.GLOBAL_LEADERBOARD),
                eq(Set.of(ZSetOperations.TypedTuple.of("honest", 50.0))));
    }

    @Test
    void rebuildSkipsRedisWhenThereIsNobodyToAdd() {
        when(userRepo.findByShadowBanned(true)).thenReturn(List.of());

        scoreService.rebuildLeaderboard(Constants.SHADOW_LEADERBOARD);

        verify(zSet, never()).add(any(), anySet());
    }

    @SuppressWarnings("unchecked")
    private void stubPipeline(long rank, double score) {
        when(redisTemplate.executePipelined(any(RedisCallback.class)))
                .thenReturn(List.of(tuples("top1", "top2"), rank, score));
    }

    private Set<ZSetOperations.TypedTuple<String>> tuples(String... ids) {
        Set<ZSetOperations.TypedTuple<String>> set = new LinkedHashSet<>();
        double score = 100;
        for (String id : ids) set.add(ZSetOperations.TypedTuple.of(id, score--));
        return set;
    }
}
