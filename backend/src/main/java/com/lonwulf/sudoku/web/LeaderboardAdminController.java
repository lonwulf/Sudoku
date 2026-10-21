package com.lonwulf.sudoku.web;

import com.lonwulf.sudoku.data.entity.LeaderboardAuditLog;
import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.data.repository.ILeaderboardAuditLogRepository;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import com.lonwulf.sudoku.service.FraudDetectionService;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
public class LeaderboardAdminController {
    private final FraudDetectionService fraudDetectionService;
    private final IUserRepository userRepository;
    private final ILeaderboardAuditLogRepository leaderboardAuditLogRepository;

    // The acting admin is always the authenticated principal, never a request parameter
    @PostMapping("/unban/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<String> unbanUser(@PathVariable String userId, Authentication authentication) {
        User user = userRepository.findById(userId).orElseThrow();
        if (!user.isShadowBanned()) {
            return ResponseEntity.badRequest().body("User is not shadow-banned");
        }
        //move back to global leaderboard
        fraudDetectionService.liftShadowBan(userId, "Admin override", adminActor(authentication));
        return ResponseEntity.ok("User " + userId + " successfully unbanned");
    }

    /**
     * Manually shadow-ban a user (admin override)
     */
    @PostMapping("/shadowban/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<String> shadowbanUser(@PathVariable String userId, Authentication authentication) {
        User user = userRepository.findById(userId).orElseThrow();
        if (user.isShadowBanned()) {
            return ResponseEntity.badRequest().body("User is already shadow-banned");
        }

        // Use the same logic as fraud detection (to move leaderboards properly)
        fraudDetectionService.flagCheating(userId, "Manual admin shadowban", adminActor(authentication));
        return ResponseEntity.ok("User " + userId + " shadow-banned");
    }

    private String adminActor(Authentication authentication) {
        return "admin:" + authentication.getName();
    }

    @GetMapping("/audit/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public List<LeaderboardAuditLog> getAuditHistory(@PathVariable String userId) {
        return leaderboardAuditLogRepository.findByUserIdOrderByTimestampDesc(userId);
    }

    @GetMapping("/audit/recent")
    @PreAuthorize("hasRole('ADMIN')")
    public List<LeaderboardAuditLog> getRecentAuditLogs(
            @RequestParam(defaultValue = "50") @Min(1) @Max(200) int limit) {
        return leaderboardAuditLogRepository
                .findAll(PageRequest.of(0, limit, Sort.by(Sort.Direction.DESC, "timestamp")))
                .getContent();
    }
}
