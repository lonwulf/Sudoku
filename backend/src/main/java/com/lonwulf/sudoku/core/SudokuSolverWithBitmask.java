package com.lonwulf.sudoku.core;

public class SudokuSolverWithBitmask {
    private final int[][] board;
    private final int[] rowMask = new int[9];
    private final int[] colMask = new int[9];
    private final int[] boxMask = new int[9];

    public SudokuSolverWithBitmask(int[][] board) {
        this.board = board;
        initMasks();
    }

    private void initMasks() {
        for (int r = 0; r < 9; r++) {
            for (int c = 0; c < 9; c++) {
                int val = board[r][c];
                if (val != 0) {
                    int bit = 1 << (val - 1);
                    rowMask[r] |= bit;
                    colMask[c] |= bit;
                    boxMask[boxIndex(r, c)] |= bit;
                }
            }
        }
    }
    private int boxIndex(int r, int c) {
        return (r / 3) * 3 + (c / 3);
    }

    public boolean solve() {
        return backtrack(0, 0);
    }

    private boolean backtrack(int r, int c) {
        if (r == 9) return true; // finished all rows

        int nextR = (c == 8) ? r + 1 : r;
        int nextC = (c + 1) % 9;

        if (board[r][c] != 0) {
            return backtrack(nextR, nextC);
        }

        int used = rowMask[r] | colMask[c] | boxMask[boxIndex(r, c)];
        int available = ~used & 0x1FF; // mask for digits 1–9

        while (available != 0) {
            int bit = Integer.lowestOneBit(available);
            int digit = Integer.numberOfTrailingZeros(bit) + 1;

            place(r, c, digit);
            if (backtrack(nextR, nextC)) return true;
            remove(r, c, digit);

            available &= ~bit; // try next candidate
        }

        return false;
    }

    private void place(int r, int c, int digit) {
        int bit = 1 << (digit - 1);
        board[r][c] = digit;
        rowMask[r] |= bit;
        colMask[c] |= bit;
        boxMask[boxIndex(r, c)] |= bit;
    }

    private void remove(int r, int c, int digit) {
        int bit = 1 << (digit - 1);
        board[r][c] = 0;
        rowMask[r] &= ~bit;
        colMask[c] &= ~bit;
        boxMask[boxIndex(r, c)] &= ~bit;
    }

    public int[][] getBoard() {
        return board;
    }

    public int countSolutions(int limit) {
        return backtrackCount(0, 0, 0, limit);
    }

    private int backtrackCount(int r, int c, int count, int limit) {
        if (count >= limit) return count; // stop early

        if (r == 9) return count + 1; // found a solution

        int nextR = (c == 8) ? r + 1 : r;
        int nextC = (c + 1) % 9;

        if (board[r][c] != 0) {
            return backtrackCount(nextR, nextC, count, limit);
        }

        int used = rowMask[r] | colMask[c] | boxMask[boxIndex(r, c)];
        int available = ~used & 0x1FF;

        while (available != 0) {
            int bit = Integer.lowestOneBit(available);
            int digit = Integer.numberOfTrailingZeros(bit) + 1;

            place(r, c, digit);
            count = backtrackCount(nextR, nextC, count, limit);
            remove(r, c, digit);

            if (count >= limit) break; // already too many solutions
            available &= ~bit;
        }

        return count;
    }

}
