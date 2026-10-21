package com.lonwulf.sudoku.data.repository;

import com.lonwulf.sudoku.data.entity.User;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface IUserRepository extends JpaRepository<User, String> {
    // Only players who have scored belong on a leaderboard
    Slice<User> findByShadowBannedAndLifetimeScoreGreaterThan(boolean shadowBanned, int score, Pageable pageable);

    boolean existsByShadowBannedAndLifetimeScoreGreaterThan(boolean shadowBanned, int score);

    // A single UPDATE, so concurrent completions by the same user can't lose an increment.
    // Clears the persistence context so a following findById sees the new values.
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("update User u set u.puzzlesCompleted = u.puzzlesCompleted + 1, u.lifetimeScore = u.lifetimeScore + :points where u.id = :id")
    int addCompletion(@Param("id") String id, @Param("points") int points);
}

