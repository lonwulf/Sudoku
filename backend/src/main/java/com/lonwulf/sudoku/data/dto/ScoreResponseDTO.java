package com.lonwulf.sudoku.data.dto;

public record ScoreResponseDTO(
        String userId,
        String displayName,
        int puzzlesCompleted,
        int leaderboardScore,
        Long rank
) {}
