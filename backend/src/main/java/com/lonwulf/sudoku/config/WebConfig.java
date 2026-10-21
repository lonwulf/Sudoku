package com.lonwulf.sudoku.config;

import com.lonwulf.sudoku.service.RateLimiter;
import com.lonwulf.sudoku.web.RateLimitInterceptor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {
    private final RateLimiter rateLimiter;
    private final int puzzlesPerMinute;
    private final int submitsPerMinute;

    public WebConfig(RateLimiter rateLimiter,
                     @Value("${sudoku.rate-limit.puzzles-per-minute}") int puzzlesPerMinute,
                     @Value("${sudoku.rate-limit.submits-per-minute}") int submitsPerMinute) {
        this.rateLimiter = rateLimiter;
        this.puzzlesPerMinute = puzzlesPerMinute;
        this.submitsPerMinute = submitsPerMinute;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // puzzle generation is the CPU-heavy, unauthenticated endpoint
        registry.addInterceptor(new RateLimitInterceptor(rateLimiter, "puzzle", puzzlesPerMinute))
                .addPathPatterns("/api/v1/sudoku/puzzle", "/api/v1/sudoku/puzzle/with-solution");
        registry.addInterceptor(new RateLimitInterceptor(rateLimiter, "submit", submitsPerMinute))
                .addPathPatterns("/api/v1/sudoku/puzzle/*/submit");
    }
}
