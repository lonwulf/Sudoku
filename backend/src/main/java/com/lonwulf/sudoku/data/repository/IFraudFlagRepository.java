package com.lonwulf.sudoku.data.repository;

import com.lonwulf.sudoku.data.entity.FraudFlag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface IFraudFlagRepository extends JpaRepository<FraudFlag, Long> {
}
