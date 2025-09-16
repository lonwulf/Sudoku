package com.lonwulf.sudoku.web;

import com.lonwulf.sudoku.data.dto.CompletionResponseDTO;
import com.lonwulf.sudoku.data.dto.ScoreRequestDTO;
import com.lonwulf.sudoku.data.dto.ScoreResponseDTO;
import com.lonwulf.sudoku.security.AuthUtil;
import com.lonwulf.sudoku.service.ScoreService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/scores")
public class ScoreController {

    private final ScoreService scoreService;
    private final AuthUtil authUtil;

    public ScoreController(ScoreService scoreService, AuthUtil authUtil) {
        this.scoreService = scoreService;
        this.authUtil = authUtil;
    }

    @PostMapping("/complete")
    public CompletionResponseDTO recordCompletion(Authentication authentication) {
        String userId = authUtil.getUserId(authentication);
        String email = authUtil.getEmail(authentication);
        String displayName = authUtil.getDisplayName(authentication);
        return scoreService.recordCompletion(userId, email, displayName);
    }

    @GetMapping("/my_score")
    public Map<String, Object> getMyScore(Authentication authentication) {
        String userId = authUtil.getUserId(authentication);
        int completed = scoreService.getCompletedCount(userId);
        return Map.of("userId", userId, "puzzlesCompleted", completed);
    }

    @PostMapping
    public ScoreResponseDTO submitScore(
            @RequestBody ScoreRequestDTO request,
            Authentication authentication
    ) {
        String userId = authUtil.getUserId(authentication);

        return scoreService.submitScore(
                userId,
                request.getPointsEarned(),
                request.isCompleted()
        );
    }
}
