package com.lonwulf.sudoku.web;

import com.lonwulf.sudoku.data.entity.LeaderboardAuditLog;
import com.lonwulf.sudoku.data.repository.ILeaderboardAuditLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/admin/audit")
@RequiredArgsConstructor
public class LeaderboardAuditController {
    private final ILeaderboardAuditLogRepository leaderboardAuditLogRepository;

    @GetMapping("/{userId}")
    public List<LeaderboardAuditLog> getUserAuditHistory(@PathVariable String userId){
        return leaderboardAuditLogRepository.findByUserIdOrderByTimestampDesc(userId);
    }

    @GetMapping("/recent")
    public List<LeaderboardAuditLog> getRecentAuditLogs(@RequestParam(defaultValue = "50") int limit){
        return leaderboardAuditLogRepository
                .findAll(PageRequest.of(0, limit, Sort.by(Sort.Direction.DESC, "timestamp")))
                .getContent();
    }
}
