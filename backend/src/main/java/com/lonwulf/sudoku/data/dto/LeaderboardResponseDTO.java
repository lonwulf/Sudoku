package com.lonwulf.sudoku.data.dto;

import java.util.List;

// Represents the whole leaderboard response
public record LeaderboardResponseDTO(
        List<LeaderboardEntryDTO> global,
        LeaderboardEntryDTO me,
        List<LeaderboardEntryDTO> nearby
) {}
