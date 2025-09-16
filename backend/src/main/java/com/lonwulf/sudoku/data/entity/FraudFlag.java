package com.lonwulf.sudoku.data.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Data;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "fraud_flags")
@Data
public class FraudFlag {
    @Id
    @GeneratedValue
    @Setter(AccessLevel.NONE)
    private Long id;
    private String userId;
    private String reason;
    private LocalDateTime timestamp;
    private boolean reviewed = false;
}
