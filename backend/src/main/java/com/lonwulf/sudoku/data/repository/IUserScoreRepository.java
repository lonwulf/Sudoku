package com.lonwulf.sudoku.data.repository;

import com.lonwulf.sudoku.data.entity.UserScore;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface IUserScoreRepository extends JpaRepository<UserScore, Long> {
    Optional<UserScore> findByUserId(String userId);
}
