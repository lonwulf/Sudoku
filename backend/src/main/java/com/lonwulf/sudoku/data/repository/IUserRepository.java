package com.lonwulf.sudoku.data.repository;

import com.lonwulf.sudoku.data.entity.User;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface IUserRepository extends JpaRepository<User, String> {
    Slice<User> findByShadowBanned(boolean shadowBanned, Pageable pageable);
}

