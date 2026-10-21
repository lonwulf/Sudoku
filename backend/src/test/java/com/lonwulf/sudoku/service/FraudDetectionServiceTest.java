package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.constants.Constants;
import com.lonwulf.sudoku.data.entity.LeaderboardAuditLog;
import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.data.repository.IFraudFlagRepository;
import com.lonwulf.sudoku.data.repository.ILeaderboardAuditLogRepository;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class FraudDetectionServiceTest {
    private IUserRepository userRepo;
    private ILeaderboardAuditLogRepository auditRepo;
    private ZSetOperations<String, String> zSet;
    private FraudDetectionService service;
    private User user;

    @BeforeEach
    @SuppressWarnings("unchecked")
    void setUp() {
        userRepo = mock(IUserRepository.class);
        auditRepo = mock(ILeaderboardAuditLogRepository.class);
        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        zSet = mock(ZSetOperations.class);
        when(redisTemplate.opsForZSet()).thenReturn(zSet);
        service = new FraudDetectionService(mock(IFraudFlagRepository.class), userRepo, redisTemplate, auditRepo);

        user = new User("cheater");
        user.setLifetimeScore(70);
        when(userRepo.findById("cheater")).thenReturn(Optional.of(user));
    }

    @Test
    void banMovesDatabaseScoreToShadowBoardAndAuditsTheActor() {
        service.flagCheating("cheater", "Manual admin shadowban", "admin:boss");

        assertTrue(user.isShadowBanned());
        verify(zSet).remove(Constants.GLOBAL_LEADERBOARD, "cheater");
        verify(zSet).add(Constants.SHADOW_LEADERBOARD, "cheater", 70.0);
        LeaderboardAuditLog log = capturedAudit();
        assertEquals(LeaderboardAuditLog.ActionType.MOVED_TO_SHADOW, log.getAction());
        assertEquals("admin:boss", log.getTriggeredBy());
    }

    @Test
    void unbanRestoresGlobalScoreEvenIfShadowBoardWasEmpty() {
        // the old unban only moved a score it found on the shadow board, so the user could vanish
        user.setShadowBanned(true);

        service.liftShadowBan("cheater", "Admin override", "admin:boss");

        assertFalse(user.isShadowBanned());
        verify(zSet).remove(Constants.SHADOW_LEADERBOARD, "cheater");
        verify(zSet).add(Constants.GLOBAL_LEADERBOARD, "cheater", 70.0);
        LeaderboardAuditLog log = capturedAudit();
        assertEquals(LeaderboardAuditLog.ActionType.MOVED_TO_GLOBAL, log.getAction());
        assertEquals("admin:boss", log.getTriggeredBy());
    }

    private LeaderboardAuditLog capturedAudit() {
        ArgumentCaptor<LeaderboardAuditLog> captor = ArgumentCaptor.forClass(LeaderboardAuditLog.class);
        verify(auditRepo).save(captor.capture());
        return captor.getValue();
    }
}
