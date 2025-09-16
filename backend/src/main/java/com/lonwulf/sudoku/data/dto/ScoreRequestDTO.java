package com.lonwulf.sudoku.data.dto;

import lombok.Data;

@Data
public class ScoreRequestDTO {
    private int pointsEarned;
    private boolean completed;
}
