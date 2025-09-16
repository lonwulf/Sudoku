package com.lonwulf.sudoku.service;

import com.lonwulf.sudoku.core.SudokuSolver;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;

@Service
public class SudokuGeneratorService {
    private final SudokuSolver solver = new SudokuSolver();
    private final Random random = new Random();

    //generate puzzle with target number of clues

    public GeneratorResult generate(String difficulty, Long seed, Integer targetClues) {
        if (seed != null) random.setSeed(seed);
        int[][] board = new int[9][9];
        fillBoardRandom(board);

        //board now full solution
        int[][] solution = copy(board);

        int clues = (targetClues != null) ? targetClues : cluesFromDifficulty(difficulty);
        removeNumbersEnsureUnique(board, clues);
        return new GeneratorResult(SudokuSolver.toList(board), SudokuSolver.toList(solution), clues);
    }

    private void fillBoardRandom(int[][] board) {
        // simple backtracking but randomize number order to produce random full board
        fillRecursive(board, 0, 0);
    }

    private boolean fillRecursive(int[][] board, int r, int c) {
        if (r == 9) return true;
        int nr = (c == 8) ? r + 1 : r;
        int nc = (c == 8) ? 0 : c + 1;
        List<Integer> nums = new ArrayList<>();
        for (int i = 1; i <= 9; i++) nums.add(i);
        Collections.shuffle(nums, random);
        for (int num : nums) {
            if (validPlace(board, r, c, num)) {
                board[r][c] = num;
                if (fillRecursive(board, nr, nc)) return true;
                board[r][c] = 0;
            }
        }
        return false;
    }

    private boolean validPlace(int[][] b, int r, int c, int num) {
        for (int i = 0; i < 9; i++) if (b[r][i] == num || b[i][c] == num) return false;
        int sr = (r / 3) * 3, sc = (c / 3) * 3;
        for (int i = 0; i < 3; i++)
            for (int j = 0; j < 3; j++)
                if (b[sr + i][sc + j] == num)
                    return false;
        return true;
    }

    private void removeNumbersEnsureUnique(int[][] board, int clues) {
        List<int[]> cells = new ArrayList<>();
        for (int r = 0; r < 9; r++)
            for (int c = 0; c < 9; c++)
                cells.add(new int[]{r, c});
        Collections.shuffle(cells, random);

        int toRemove = 81 - clues;
        for (int[] pos : cells) {
            if (toRemove <= 0) break;
            int r = pos[0], c = pos[1];
            if (board[r][c] == 0) continue;
            int backup = board[r][c];
            board[r][c] = 0;

            //check uniqueness
            int[][] copy = copy(board);
            int solCount = solver.countSolutions(copy, 2); //stop at 2
            if (solCount != -1) {
                //reverting
                board[r][c] = backup;
            } else {
                toRemove--;
            }
        }
    }

    private int cluesFromDifficulty(String difficulty) {
        return switch ((difficulty == null ? "medium" : difficulty).toLowerCase()) {
            case "easy" -> 38;
            case "hard" -> 26;
            default -> 32; //medium
        };
    }

    private int[][] copy(int[][] src) {
        int[][] d = new int[9][9];
        for (int i = 0; i < 9; i++) System.arraycopy(src[i], 0, d[i], 0, 9);
        return d;
    }

    public static class GeneratorResult {
        public final List<List<Integer>> puzzle;
        public final List<List<Integer>> solution;
        public final int clues;

        public GeneratorResult(List<List<Integer>> puzzle, List<List<Integer>> solution, int clues) {
            this.puzzle = puzzle;
            this.solution = solution;
            this.clues = clues;
        }
    }

}
