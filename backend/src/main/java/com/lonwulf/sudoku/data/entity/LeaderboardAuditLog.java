package com.lonwulf.sudoku.data.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Data;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "leaderboard_audit_log")
@Data
public class LeaderboardAuditLog {
    @Id
    @GeneratedValue
    @Setter(AccessLevel.NONE)
    private Long id;

    private String userId;

    @Enumerated(EnumType.STRING)
    private ActionType action;

    private String reason;

    private String triggeredBy; // "fraud-detection" or "admin"

    private LocalDateTime timestamp;

    public enum ActionType {
        MOVED_TO_SHADOW,
        MOVED_TO_GLOBAL
    }
}
