package com.lonwulf.sudoku.web;

import com.lonwulf.sudoku.security.AuthUtil;
import com.lonwulf.sudoku.service.ScoreService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

// Scores are only awarded by POST /api/v1/sudoku/puzzle/{id}/submit after the server checks the solution
@RestController
@RequestMapping("/scores")
public class ScoreController {

    private final ScoreService scoreService;
    private final AuthUtil authUtil;

    public ScoreController(ScoreService scoreService, AuthUtil authUtil) {
        this.scoreService = scoreService;
        this.authUtil = authUtil;
    }

    @GetMapping("/my_score")
    public Map<String, Object> getMyScore(Authentication authentication) {
        String userId = authUtil.ensureUserExists(authentication).getId();
        int completed = scoreService.getCompletedCount(userId);
        return Map.of("userId", userId, "puzzlesCompleted", completed);
    }
}
