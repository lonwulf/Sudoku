package com.lonwulf.sudoku.data.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_scores")
@Data
@NoArgsConstructor
public class UserScore {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Setter(AccessLevel.NONE)
    private Long id;

    private String userId; // google account sub
    private int puzzlesCompleted = 0;
    private int totalPoints = 0;
    private LocalDateTime lastUpdated = LocalDateTime.now();

    public UserScore(String userId) {
        this.userId = userId;
    }

    public void increment() {
        this.puzzlesCompleted++;
    }
}
