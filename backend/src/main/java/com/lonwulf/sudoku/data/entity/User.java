package com.lonwulf.sudoku.data.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "users")
@Getter
@Setter
public class User {
    @Id
    private String id;
    private String email;
    private String displayName;
    private int puzzlesCompleted;
    private boolean shadowBanned;
    private int lifetimeScore; // SQL persistent score

    public User() {
    }
    public User(String id) {
        this.id = id;
    }
    public void incrementPuzzlesCompleted() {
        this.puzzlesCompleted++;
    }

    public void addScore(int score) {
        this.lifetimeScore += score;
    }

}

