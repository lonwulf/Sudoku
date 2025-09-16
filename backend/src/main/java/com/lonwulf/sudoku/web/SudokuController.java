package com.lonwulf.sudoku.web;

import com.lonwulf.sudoku.data.dto.SudokuPublicResponseDTO;
import com.lonwulf.sudoku.data.dto.SudokuResponseDTO;
import com.lonwulf.sudoku.security.AuthUtil;
import com.lonwulf.sudoku.service.ScoreService;
import com.lonwulf.sudoku.service.SudokuCacheService;
import com.lonwulf.sudoku.service.SudokuGeneratorServiceWithBitmask;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/sudoku")
public class SudokuController {
//    private final SudokuGeneratorService generatorService;

//    public SudokuController(SudokuGeneratorService generatorService) {
//        this.generatorService = generatorService;
//    }

    //    @GetMapping("/api/v1/sudoku")
//    public SudokuResponseDTO getSudoku(
//            @RequestParam(value = "difficulty", required = false) String difficulty,
//            @RequestParam(value = "seed", required = false) Long seed,
//            @RequestParam(value = "clues", required = false) Integer clues,
//            @RequestParam(value = "includeSolution", required = false, defaultValue = "false") boolean includeSolution
//    ) {
//        var res = generatorService.generate(difficulty, seed, clues);
//        String id = UUID.randomUUID().toString();
//        return new SudokuResponseDTO(id, difficulty == null ? "medium" : difficulty, res.puzzle, includeSolution ? res.solution : null);
//    }
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
        String id = UUID.randomUUID().toString();
        int[][] puzzle = generatorService.generatePuzzle(difficulty);

        return new SudokuPublicResponseDTO(
                id,
                difficulty,
                toList(puzzle)
        );
    }

    // Optional: Admin/debug endpoint that includes solution
    @GetMapping("/puzzle/with-solution")
    public SudokuResponseDTO getPuzzleWithSolution(
            @RequestParam(defaultValue = "medium") String difficulty
    ) {
        String id = UUID.randomUUID().toString();
        int[][] puzzle = generatorService.generatePuzzle(difficulty);
        int[][] solution = generatorService.generateSolvedBoard();

        return new SudokuResponseDTO(
                id,
                difficulty,
                toList(puzzle),
                toList(solution)
        );
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
        String userId = authUtil.getUserId(authentication);
        String email = authUtil.getEmail(authentication);
        String displayName = authUtil.getDisplayName(authentication);

        int[][] correctSolution = cacheService.getSolution(id);
        if (correctSolution == null) {
            return ResponseEntity.badRequest().body(Map.of("status", "error", "message", "Puzzle expired or not found"));
        }

        int[][] attemptedArray = attempted.stream()
                .map(row -> row.stream().mapToInt(Integer::intValue).toArray())
                .toArray(int[][]::new);

        boolean isCorrect = Arrays.deepEquals(correctSolution, attemptedArray);
        if (!isCorrect) {
            return ResponseEntity.badRequest().body(Map.of("status", "error", "message", "Incorrect solution"));
        }
        scoreService.recordCompletion(userId, email, displayName);
        return ResponseEntity.ok(Map.of("status", "success", "message", "Puzzle solved!"));
    }
}
