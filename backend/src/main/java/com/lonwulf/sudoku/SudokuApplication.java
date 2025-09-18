package com.lonwulf.sudoku;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class SudokuApplication {

	public static void main(String[] args) {
		SpringApplication.run(SudokuApplication.class, args);
	}

}
