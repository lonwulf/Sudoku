package com.lonwulf.sudoku.web;

import com.lonwulf.sudoku.data.dto.SudokuPublicResponseDTO;
import com.lonwulf.sudoku.data.dto.SudokuResponseDTO;
import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.security.AuthUtil;
import com.lonwulf.sudoku.service.ScoreService;
import com.lonwulf.sudoku.service.SudokuCacheService;
import com.lonwulf.sudoku.service.SudokuGeneratorServiceWithBitmask;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/sudoku")
public class SudokuController {
    private static final Set<String> DIFFICULTIES = Set.of("easy", "medium", "hard");

    private final SudokuGeneratorServiceWithBitmask generatorService;
    private final SudokuCacheService cacheService;
    private final ScoreService scoreService;
    private final AuthUtil authUtil;

    public SudokuController(SudokuGeneratorServiceWithBitmask generatorService, AuthUtil authUtil, SudokuCacheService cacheService, ScoreService scoreService) {
        this.generatorService = generatorService;
        this.authUtil = authUtil;
        this.cacheService = cacheService;
        this.scoreService = scoreService;
    }

    @GetMapping("/puzzle")
    public SudokuPublicResponseDTO getPuzzle(
            @RequestParam(defaultValue = "medium") String difficulty
    ) {
        String level = normalizeDifficulty(difficulty);
        String id = UUID.randomUUID().toString();
        SudokuGeneratorServiceWithBitmask.Puzzle puzzle = newPuzzle(id, level);

        return new SudokuPublicResponseDTO(
                id,
                level,
                toList(puzzle.puzzle())
        );
    }

    // Used by the mobile client for local mistake highlighting and hints.
    // Points are still only awarded through /submit, once per puzzle id.
    @GetMapping("/puzzle/with-solution")
    public SudokuResponseDTO getPuzzleWithSolution(
            @RequestParam(defaultValue = "medium") String difficulty
    ) {
        String level = normalizeDifficulty(difficulty);
        String id = UUID.randomUUID().toString();
        SudokuGeneratorServiceWithBitmask.Puzzle puzzle = newPuzzle(id, level);

        return new SudokuResponseDTO(
                id,
                level,
                toList(puzzle.puzzle()),
                toList(puzzle.solution())
        );
    }

    private SudokuGeneratorServiceWithBitmask.Puzzle newPuzzle(String id, String difficulty) {
        SudokuGeneratorServiceWithBitmask.Puzzle puzzle = generatorService.generatePuzzle(difficulty);
        cacheService.savePuzzle(id, difficulty, puzzle.solution());
        return puzzle;
    }

    private String normalizeDifficulty(String difficulty) {
        String level = difficulty.toLowerCase(Locale.ROOT);
        if (!DIFFICULTIES.contains(level)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "difficulty must be one of " + DIFFICULTIES);
        }
        return level;
    }

    /**
     * Utility to convert int[][] -> List<List<Integer>>
     */
    private List<List<Integer>> toList(int[][] grid) {
        return Arrays.stream(grid)
                .map(row -> Arrays.stream(row).boxed().toList())
                .toList();
    }

    @PostMapping("/puzzle/{id}/submit")
    public ResponseEntity<?> submitSolution(@PathVariable String id, @RequestBody List<List<Integer>> attempted, Authentication authentication) {
        SudokuCacheService.CachedPuzzle cached = cacheService.getPuzzle(id);
        if (cached == null) {
            return ResponseEntity.badRequest().body(Map.of("status", "error", "message", "Puzzle expired or not found"));
        }

        if (!matchesSolution(cached.solution(), attempted)) {
            return ResponseEntity.badRequest().body(Map.of("status", "error", "message", "Incorrect solution"));
        }

        // only the first correct submit for this id is scored
        if (!cacheService.consume(id)) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("status", "error", "message", "Puzzle already submitted"));
        }

        User user = authUtil.ensureUserExists(authentication);
        return ResponseEntity.ok(scoreService.recordCompletion(user, ScoreService.pointsForDifficulty(cached.difficulty())));
    }

    private boolean matchesSolution(int[][] solution, List<List<Integer>> attempted) {
        if (attempted == null || attempted.size() != 9) return false;
        for (int r = 0; r < 9; r++) {
            List<Integer> row = attempted.get(r);
            if (row == null || row.size() != 9) return false;
            for (int c = 0; c < 9; c++) {
                if (!Integer.valueOf(solution[r][c]).equals(row.get(c))) return false;
            }
        }
        return true;
    }
}
