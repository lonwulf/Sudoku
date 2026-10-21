package com.lonwulf.sudoku.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Arrays;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class SudokuCacheService {
    private final StringRedisTemplate redisTemplate;
    private final Duration puzzleTtl;
    public static final String PUZZLE_KEY_PREFIX = "sudoku:puzzle:";
    private static final String SOLUTION_FIELD = "solution";
    private static final String DIFFICULTY_FIELD = "difficulty";

    public SudokuCacheService(StringRedisTemplate redisTemplate,
                              @Value("${sudoku.puzzle-ttl}") Duration puzzleTtl) {
        this.redisTemplate = redisTemplate;
        this.puzzleTtl = puzzleTtl;
    }

    public void savePuzzle(String puzzleId, String difficulty, int[][] solution) {
        String key = PUZZLE_KEY_PREFIX + puzzleId;
        redisTemplate.opsForHash().putAll(key, Map.of(
                SOLUTION_FIELD, serialize(solution),
                DIFFICULTY_FIELD, difficulty
        ));
        redisTemplate.expire(key, puzzleTtl);
    }

    public CachedPuzzle getPuzzle(String puzzleId) {
        String key = PUZZLE_KEY_PREFIX + puzzleId;
        Map<Object, Object> fields = redisTemplate.opsForHash().entries(key);
        Object solution = fields.get(SOLUTION_FIELD);
        if (solution == null) return null;
        return new CachedPuzzle((String) fields.get(DIFFICULTY_FIELD), deserialize((String) solution));
    }

    /**
     * Removes the puzzle so its solution can only be redeemed once.
     * Returns false if it was already gone (expired, or claimed by a concurrent submit).
     */
    public boolean consume(String puzzleId) {
        return Boolean.TRUE.equals(redisTemplate.delete(PUZZLE_KEY_PREFIX + puzzleId));
    }

    private String serialize(int[][] board) {
        return Arrays.stream(board)
                .map(row -> Arrays.stream(row).mapToObj(String::valueOf).collect(Collectors.joining(",")))
                .collect(Collectors.joining(";"));
    }

    private int[][] deserialize(String data) {
        String[] rows = data.split(";");
        int[][] board = new int[9][9];
        for (int i = 0; i < 9; i++) {
            String[] cols = rows[i].split(",");
            for (int j = 0; j < 9; j++) {
                board[i][j] = Integer.parseInt(cols[j]);
            }
        }
        return board;
    }

    public record CachedPuzzle(String difficulty, int[][] solution) {
    }
}
