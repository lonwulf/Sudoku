package com.lonwulf.sudoku.data.dto;

import java.util.List;

public record SudokuPublicResponseDTO(
        String id,
        String difficulty,
        List<List<Integer>> puzzle
) {
}
