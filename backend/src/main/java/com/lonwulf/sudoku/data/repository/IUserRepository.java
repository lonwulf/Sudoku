package com.lonwulf.sudoku.data.repository;

import com.lonwulf.sudoku.data.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface IUserRepository extends JpaRepository<User, String> {
}

