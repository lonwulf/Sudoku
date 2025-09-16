package com.lonwulf.sudoku.data.dto;

import java.util.List;

public record SudokuResponseDTO(String id, String difficulty, List<List<Integer>> puzzle,
                                List<List<Integer>> solution) {

}
