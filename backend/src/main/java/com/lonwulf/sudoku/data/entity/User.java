package com.lonwulf.sudoku.data.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PostLoad;
import jakarta.persistence.PostPersist;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.Setter;
import org.springframework.data.domain.Persistable;

@Entity
@Table(name = "users")
@Getter
@Setter
public class User implements Persistable<String> {
    @Id
    private String id;
    private String email;
    private String displayName;
    private int puzzlesCompleted;
    private boolean shadowBanned;
    private int lifetimeScore; // SQL persistent score

    // The id is assigned (the auth subject), so Spring Data can't infer newness from a null id.
    // New users are INSERTed (a duplicate fails) instead of merged over an existing row.
    @Transient
    @Getter(AccessLevel.NONE)
    @Setter(AccessLevel.NONE)
    private boolean newUser;

    public User() {
    }
    public User(String id) {
        this.id = id;
        this.newUser = true;
    }
    public void incrementPuzzlesCompleted() {
        this.puzzlesCompleted++;
    }

    public void addScore(int score) {
        this.lifetimeScore += score;
    }

    @Override
    public boolean isNew() {
        return newUser;
    }

    @PostLoad
    @PostPersist
    void markNotNew() {
        this.newUser = false;
    }

}
