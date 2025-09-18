package com.lonwulf.sudoku.data.dto;

import java.util.List;

// Represents the whole leaderboard response
public record LeaderboardResponseDTO(
        List<LeaderboardEntryDTO> global,
        LeaderboardEntryDTO me,
        List<LeaderboardEntryDTO> nearby,
        String state,
        String message,
        Integer retryAfterSeconds
) {
    public static LeaderboardResponseDTO initializing(int retryAfter){
        return new LeaderboardResponseDTO(
                List.of(),
                null,
                List.of(),
                "initializing",
                "Leaderboard is warming up, please retry later",
                retryAfter
        );
    }

    public static LeaderboardResponseDTO ready(
            List<LeaderboardEntryDTO> global,
            LeaderboardEntryDTO me,
            List<LeaderboardEntryDTO> nearby
    ) {
        return new LeaderboardResponseDTO(
                global,
                me,
                nearby,
                "ready",
                "ok",
                0
        );
    }
}
