package com.lonwulf.sudoku.web;

import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.security.AuthUtil;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

// Scores are only awarded by POST /api/v1/sudoku/puzzle/{id}/submit after the server checks the solution
@RestController
@RequestMapping("/scores")
public class ScoreController {

    private final AuthUtil authUtil;

    public ScoreController(AuthUtil authUtil) {
        this.authUtil = authUtil;
    }

    @GetMapping("/my_score")
    public Map<String, Object> getMyScore(Authentication authentication) {
        User user = authUtil.ensureUserExists(authentication);
        return Map.of("userId", user.getId(), "puzzlesCompleted", user.getPuzzlesCompleted());
    }
}
