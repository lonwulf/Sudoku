package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.core.SudokuSolverWithBitmask;
import org.springframework.stereotype.Service;

import java.util.Random;

@Service
public class SudokuGeneratorServiceWithBitmask {
    private final Random random = new Random();

    public int[][] generateSolvedBoard() {
        int[][] board = new int[9][9];
        SudokuSolverWithBitmask solver = new SudokuSolverWithBitmask(board);
        solver.solve();
        return solver.getBoard();
    }

    public int[][] generatePuzzle(String difficulty) {
        int[][] solution = generateSolvedBoard();
        int[][] puzzle = deepCopy(solution);

        int removals = switch (difficulty.toLowerCase()) {
            case "easy" -> 35;
            case "medium" -> 45;
            case "hard" -> 55;
            default -> 40;
        };

        while (removals > 0) {
            int r = random.nextInt(9);
            int c = random.nextInt(9);

            if (puzzle[r][c] != 0) {
                int backup = puzzle[r][c];
                puzzle[r][c] = 0;

                if (!hasUniqueSolution(deepCopy(puzzle))) {
                    puzzle[r][c] = backup; // restore if uniqueness broken
                } else {
                    removals--;
                }
            }
        }

        return puzzle;
    }

    private boolean hasUniqueSolution(int[][] puzzle) {
        SudokuSolverWithBitmask solver = new SudokuSolverWithBitmask(puzzle);
//        return solver.solve(); // we only check solvability & uniqueness here
        return solver.countSolutions(2) == 1;
    }

    private int[][] deepCopy(int[][] src) {
        int[][] copy = new int[9][9];
        for (int i = 0; i < 9; i++) {
            System.arraycopy(src[i], 0, copy[i], 0, 9);
        }
        return copy;
    }
}
