package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.constants.Constants;
import com.lonwulf.sudoku.data.entity.FraudFlag;
import com.lonwulf.sudoku.data.entity.LeaderboardAuditLog;
import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.data.repository.IFraudFlagRepository;
import com.lonwulf.sudoku.data.repository.ILeaderboardAuditLogRepository;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class FraudDetectionService {
    private final IFraudFlagRepository fraudFlagRepository;
    private final IUserRepository userRepository;
    private final StringRedisTemplate redisTemplate;
    private final ILeaderboardAuditLogRepository leaderboardAuditLogRepository;

    /**
     * @param triggeredBy "fraud-detection" or "admin:&lt;authenticated admin&gt;"
     */
    @Transactional
    public void flagCheating(String userId, String reason, String triggeredBy) {
        FraudFlag flag = new FraudFlag();
        flag.setUserId(userId);
        flag.setReason(reason);
        flag.setTimestamp(LocalDateTime.now());
        fraudFlagRepository.save(flag);

        User user = userRepository.findById(userId).orElseThrow();
        user.setShadowBanned(true);
        userRepository.save(user);

        // Move score from global → shadow leaderboard
        moveBetweenLeaderboards(user, Constants.GLOBAL_LEADERBOARD, Constants.SHADOW_LEADERBOARD);
        audit(userId, LeaderboardAuditLog.ActionType.MOVED_TO_SHADOW, reason, triggeredBy);
    }

    @Transactional
    public void liftShadowBan(String userId, String reason, String triggeredBy) {
        User user = userRepository.findById(userId).orElseThrow();
        if (!user.isShadowBanned()) return;

        user.setShadowBanned(false);
        userRepository.save(user);

        // Move score from shadow → global leaderboard
        moveBetweenLeaderboards(user, Constants.SHADOW_LEADERBOARD, Constants.GLOBAL_LEADERBOARD);
        audit(userId, LeaderboardAuditLog.ActionType.MOVED_TO_GLOBAL, reason, triggeredBy);
    }

    // The database score is the source of truth, so this works even if the user was never on the source board.
    // Runs after commit so a rolled-back ban never moves the board.
    private void moveBetweenLeaderboards(User user, String from, String to) {
        String userId = user.getId();
        int score = user.getLifetimeScore();
        afterCommit(() -> {
            redisTemplate.opsForZSet().remove(from, userId);
            redisTemplate.opsForZSet().add(to, userId, score);
        });
    }

    private void afterCommit(Runnable action) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            action.run(); // no surrounding transaction (e.g. unit tests)
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                action.run();
            }
        });
    }

    private void audit(String userId, LeaderboardAuditLog.ActionType action, String reason, String triggeredBy) {
        LeaderboardAuditLog auditLog = new LeaderboardAuditLog();
        auditLog.setUserId(userId);
        auditLog.setAction(action);
        auditLog.setReason(reason);
        auditLog.setTriggeredBy(triggeredBy);
        auditLog.setTimestamp(LocalDateTime.now());
        leaderboardAuditLogRepository.save(auditLog);
    }
}
