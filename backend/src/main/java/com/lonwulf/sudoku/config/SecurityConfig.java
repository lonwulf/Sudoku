package com.lonwulf.sudoku.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity httpSecurity) throws Exception {
        httpSecurity.authorizeHttpRequests(auth ->
                        auth.requestMatchers("/sudoku/**").permitAll() // anyone can fetch puzzles
                                .requestMatchers("/scores/**").authenticated()) //only logged in users can post scores
                .oauth2ResourceServer(oath2 -> oath2.jwt());
        return httpSecurity.build();
    }
}
