package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.core.SudokuSolverWithBitmask;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.util.concurrent.ThreadLocalRandom;

@Service
public class SudokuGeneratorServiceWithBitmask {

    public int[][] generateSolvedBoard() {
        int[][] board = new int[9][9];
        SudokuSolverWithBitmask solver = new SudokuSolverWithBitmask(board, ThreadLocalRandom.current());
        solver.solve();
        return solver.getBoard();
    }

    public Puzzle generatePuzzle(String difficulty) {
        Random random = ThreadLocalRandom.current();
        int[][] solution = generateSolvedBoard();
        int[][] puzzle = deepCopy(solution);

        int removals = switch (difficulty) {
            case "easy" -> 35;
            case "medium" -> 45;
            case "hard" -> 55;
            default -> throw new IllegalArgumentException("Unknown difficulty: " + difficulty);
        };

        List<int[]> cells = new ArrayList<>(81);
        for (int r = 0; r < 9; r++)
            for (int c = 0; c < 9; c++)
                cells.add(new int[]{r, c});
        Collections.shuffle(cells, random);

        // single pass: once every cell has been tried we stop, even if fewer than `removals`
        // could be blanked while keeping a unique solution (the puzzle is then slightly easier)
        for (int[] cell : cells) {
            if (removals == 0) break;
            int r = cell[0], c = cell[1];
            int backup = puzzle[r][c];
            puzzle[r][c] = 0;

            if (hasUniqueSolution(deepCopy(puzzle))) {
                removals--;
            } else {
                puzzle[r][c] = backup; // restore if uniqueness broken
            }
        }

        return new Puzzle(puzzle, solution);
    }

    private boolean hasUniqueSolution(int[][] puzzle) {
        SudokuSolverWithBitmask solver = new SudokuSolverWithBitmask(puzzle);
        return solver.countSolutions(2) == 1;
    }

    private int[][] deepCopy(int[][] src) {
        int[][] copy = new int[9][9];
        for (int i = 0; i < 9; i++) {
            System.arraycopy(src[i], 0, copy[i], 0, 9);
        }
        return copy;
    }

    public record Puzzle(int[][] puzzle, int[][] solution) {
    }
}
