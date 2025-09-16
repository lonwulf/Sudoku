package com.lonwulf.sudoku.service;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Arrays;
import java.util.stream.Collectors;

@Service
public class SudokuCacheService {
    private final StringRedisTemplate redisTemplate;
    public static final String PUZZLE_KEY_PREFIX = "sudoku:puzzle";

    public SudokuCacheService(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    public void saveSolution(String puzzleId, int[][] solution) {
        String key = PUZZLE_KEY_PREFIX + puzzleId;
        String serialized = serialize(solution);
        redisTemplate.opsForValue().set(key, serialized, Duration.ofHours(1));//expire in 1 hr
    }

    public int[][] getSolution(String puzzleId) {
        String key = PUZZLE_KEY_PREFIX + puzzleId;
        String serialized = redisTemplate.opsForValue().get(key);
        if (serialized == null) return null;
        return deserialize(serialized);
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
}
