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

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class FraudDetectionService {
    private final IFraudFlagRepository fraudFlagRepository;
    private final IUserRepository userRepository;
    private final StringRedisTemplate redisTemplate;
    private final ILeaderboardAuditLogRepository leaderboardAuditLogRepository;

    public void flagCheating(String userId, String reason) {
        FraudFlag flag = new FraudFlag();
        flag.setUserId(userId);
        flag.setReason(reason);
        flag.setTimestamp(LocalDateTime.now());
        fraudFlagRepository.save(flag);

        User user = userRepository.findById(userId).orElseThrow();
        user.setShadowBanned(true);
        userRepository.save(user);

        // Move score from global → shadow leaderboard
        Double score = redisTemplate.opsForZSet().score(Constants.GLOBAL_LEADERBOARD, userId);
        if (score != null) {
            redisTemplate.opsForZSet()
                    .remove(Constants.GLOBAL_LEADERBOARD, userId);
            redisTemplate.opsForZSet()
                    .add(Constants.SHADOW_LEADERBOARD, userId, score);
        }

        LeaderboardAuditLog auditLog = new LeaderboardAuditLog();
        auditLog.setUserId(userId);
        auditLog.setAction(LeaderboardAuditLog.ActionType.MOVED_TO_SHADOW);
        auditLog.setReason(reason);
        auditLog.setTriggeredBy("fraud-detection");
        auditLog.setTimestamp(LocalDateTime.now());

        leaderboardAuditLogRepository.save(auditLog);
    }
}
