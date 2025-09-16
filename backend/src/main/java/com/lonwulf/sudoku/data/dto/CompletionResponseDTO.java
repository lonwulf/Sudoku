package com.lonwulf.sudoku.data.dto;

// DTO for completion endpoint
public record CompletionResponseDTO(
        String userId,
        int puzzlesCompleted
) {}