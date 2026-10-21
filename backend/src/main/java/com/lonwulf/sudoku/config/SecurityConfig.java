package com.lonwulf.sudoku.config;

import com.lonwulf.sudoku.security.JwtRoleConverter;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity httpSecurity,
                                           JwtRoleConverter jwtRoleConverter,
                                           ObjectProvider<UserDetailsService> userDetailsService) throws Exception {
        JwtAuthenticationConverter jwtAuthenticationConverter = new JwtAuthenticationConverter();
        jwtAuthenticationConverter.setJwtGrantedAuthoritiesConverter(jwtRoleConverter);

        httpSecurity
                .csrf(AbstractHttpConfigurer::disable) // stateless bearer-token API, no session cookies
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth ->
                        auth.requestMatchers(HttpMethod.GET, "/api/v1/sudoku/puzzle", "/api/v1/sudoku/puzzle/with-solution").permitAll() // anyone can fetch puzzles
                                .requestMatchers("/actuator/health", "/actuator/info", "/error").permitAll()
                                .requestMatchers("/admin/**").hasRole("ADMIN")
                                .anyRequest().authenticated()) // submitting, scores and leaderboard need a logged in user
                .oauth2ResourceServer(oauth2 -> oauth2.jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter)));

        // basic auth only exists for the dev profile's in-memory users
        if (userDetailsService.getIfAvailable() != null) {
            httpSecurity.httpBasic(Customizer.withDefaults());
        }
        return httpSecurity.build();
    }
}
