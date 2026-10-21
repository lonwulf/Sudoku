package com.lonwulf.sudoku.web;

import com.lonwulf.sudoku.data.dto.ScoreResponseDTO;
import com.lonwulf.sudoku.security.AuthUtil;
import com.lonwulf.sudoku.service.ScoreService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

// Scores are only awarded by POST /api/v1/sudoku/puzzle/{id}/submit after the server checks the solution
@RestController
@RequestMapping("/scores")
public class ScoreController {

    private final AuthUtil authUtil;
    private final ScoreService scoreService;

    public ScoreController(AuthUtil authUtil, ScoreService scoreService) {
        this.authUtil = authUtil;
        this.scoreService = scoreService;
    }

    @GetMapping("/my_score")
    public ScoreResponseDTO getMyScore(Authentication authentication) {
        return scoreService.getStanding(authUtil.ensureUserExists(authentication));
    }
}
