package com.lonwulf.sudoku.data.dto;

// Represents one entry in the leaderboard
public record LeaderboardEntryDTO(
        long rank,
        String userId,
        String displayName,
        int leaderboardScore
) {
}
