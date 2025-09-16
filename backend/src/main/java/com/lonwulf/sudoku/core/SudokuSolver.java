package com.lonwulf.sudoku.core;

import java.util.ArrayList;
import java.util.List;

public class SudokuSolver {
    public static final int SIZE = 9;
    public static final int EMPTY = 0;

    public boolean solve(int[][] board) {
        int[] pos = findEmptyWithLeastCandidates(board);
        if (pos == null) return true; //solved

        int r = pos[0], c = pos[1];
        boolean[] used = usedInCell(board, r, c);
        for (int num = 1; num <= 9; num++) {
            if (!used[num]) {
                board[r][c] = num;
                if (solve(board)) return true;
                board[r][c] = EMPTY;
            }
        }
        return false;
    }

    //count solutions upto limit and return count
    public int countSolutions(int[][] board, int limit) {
        return countSolutionsHelper(board, limit, 0);
    }

    public int countSolutionsHelper(int[][] board, int limit, int depth) {
        if (depth > 10000) {
            //safeguard to avoid pathological runs
        }
        int[] pos = findEmptyWithLeastCandidates(board);
        if (pos == null) return 1;

        int r = pos[0], c = pos[1];
        boolean[] used = usedInCell(board, r, c);
        int total = 0;
        for (int num = 1; num < +9; num++) {
            if (!used[num]) {
                board[r][c] = num;
                total += countSolutionsHelper(board, limit, depth + 1);
                board[r][c] = EMPTY;
                if (total >= limit) return total;
            }
        }
        return total;
    }

    private int[] findEmptyWithLeastCandidates(int[][] board) {
        int bestR = -1, bestC = -1, bestCount = Integer.MAX_VALUE;
        for (int r = 0; r < SIZE; r++) {
            for (int c = 0; c < SIZE; c++) {
                if (board[r][c] == EMPTY) {
                    boolean[] used = usedInCell(board, r, c);
                    int count = 0;
                    for (int n = 1; n <= 9; n++) if (!used[n]) count++;
                    if (count < bestCount) {
                        bestCount = count;
                        bestR = r;
                        bestC = c;
                        if (count == 1) return new int[]{bestR, bestC};
                    }
                }
            }
        }
        return bestR == -1 ? null : new int[]{bestR, bestC};
    }

    private boolean[] usedInCell(int[][] board, int r, int c) {
        boolean[] used = new boolean[10];
        for (int i = 0; i < 9; i++) {
            int v = board[r][i];
            if (v != EMPTY) used[v] = true;
            v = board[i][c];
            if (v != EMPTY) used[v] = true;
        }
        int sr = (r / 3) * 3, sc = (c / 3) * 3;
        for (int i = 0; i < 3; i++)
            for (int j = 0; j < 3; j++) {
                int v = board[sr + i][sc + j];
                if (v != EMPTY) used[v] = true;
            }
        return used;
    }

    //convert board to List<List<Integer>>
    public static List<List<Integer>> toList(int[][] board){
        List<List<Integer>> out = new ArrayList<>(9);
        for (int r =0; r<9; r++){
            List<Integer> row = new ArrayList<>(9);
            for (int c =0; c<9; c++) row.add(board[r][c]);
            out.add(row);
        }
        return out;
    }

}
