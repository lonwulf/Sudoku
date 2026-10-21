package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.core.SudokuSolverWithBitmask;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTimeoutPreemptively;
import static org.junit.jupiter.api.Assertions.assertTrue;

class SudokuGeneratorServiceWithBitmaskTest {
    private final SudokuGeneratorServiceWithBitmask generator = new SudokuGeneratorServiceWithBitmask();

    @Test
    void solvedBoardsAreRandom() {
        Set<String> boards = new HashSet<>();
        for (int i = 0; i < 20; i++) boards.add(Arrays.deepToString(generator.generateSolvedBoard()));
        assertTrue(boards.size() > 1, "every solved board was identical");
    }

    @Test
    void hardPuzzlesAlwaysFinishWithUniqueMatchingSolution() {
        // the old random-retry loop never finished on roughly 15% of hard puzzles
        assertTimeoutPreemptively(Duration.ofSeconds(30), () -> {
            for (int i = 0; i < 200; i++) {
                SudokuGeneratorServiceWithBitmask.Puzzle p = generator.generatePuzzle("hard");
                assertValidSolution(p.solution());
                for (int r = 0; r < 9; r++)
                    for (int c = 0; c < 9; c++)
                        assertTrue(p.puzzle()[r][c] == 0 || p.puzzle()[r][c] == p.solution()[r][c]);

                int[][] copy = new int[9][9];
                for (int r = 0; r < 9; r++) copy[r] = p.puzzle()[r].clone();
                assertEquals(1, new SudokuSolverWithBitmask(copy).countSolutions(2));
            }
        });
    }

    private void assertValidSolution(int[][] b) {
        for (int i = 0; i < 9; i++) {
            Set<Integer> row = new HashSet<>(), col = new HashSet<>(), box = new HashSet<>();
            for (int j = 0; j < 9; j++) {
                row.add(b[i][j]);
                col.add(b[j][i]);
                box.add(b[(i / 3) * 3 + j / 3][(i % 3) * 3 + j % 3]);
            }
            assertEquals(Set.of(1, 2, 3, 4, 5, 6, 7, 8, 9), row);
            assertEquals(Set.of(1, 2, 3, 4, 5, 6, 7, 8, 9), col);
            assertEquals(Set.of(1, 2, 3, 4, 5, 6, 7, 8, 9), box);
        }
    }
}
