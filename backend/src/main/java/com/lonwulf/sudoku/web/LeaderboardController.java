package com.lonwulf.sudoku.web;

import com.lonwulf.sudoku.data.dto.LeaderboardResponseDTO;
import com.lonwulf.sudoku.security.AuthUtil;
import com.lonwulf.sudoku.service.ScoreService;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/leaderboard")
public class LeaderboardController {
    private final ScoreService scoreService;
    private final AuthUtil authUtil;

    public LeaderboardController(ScoreService scoreService, AuthUtil authUtil) {
        this.scoreService = scoreService;
        this.authUtil = authUtil;
    }

    @GetMapping
    public LeaderboardResponseDTO getLeaderboard(
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "10") @Min(1) @Max(100) int size,
            @RequestParam(defaultValue = "2") @Min(1) @Max(10) int window,
            Authentication authentication
    ) {
        String userId = authUtil.getUserId(authentication);
        return scoreService.getLeaderboardData(userId, page, size, window);
    }
}
