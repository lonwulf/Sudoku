package com.lonwulf.sudoku.data.repository;

import com.lonwulf.sudoku.data.entity.LeaderboardAuditLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ILeaderboardAuditLogRepository extends JpaRepository<LeaderboardAuditLog, Long> {
    List<LeaderboardAuditLog> findByUserIdOrderByTimestampDesc(String userId);
}
