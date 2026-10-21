package com.lonwulf.sudoku.web;

import com.lonwulf.sudoku.service.RateLimiter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Limits one bucket of endpoints per client: the authenticated user, else the remote address.
 * Behind a reverse proxy the remote address comes from X-Forwarded-For (server.forward-headers-strategy).
 */
public class RateLimitInterceptor implements HandlerInterceptor {
    private final RateLimiter rateLimiter;
    private final String bucket;
    private final int limitPerMinute;

    public RateLimitInterceptor(RateLimiter rateLimiter, String bucket, int limitPerMinute) {
        this.rateLimiter = rateLimiter;
        this.bucket = bucket;
        this.limitPerMinute = limitPerMinute;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        long retryAfter = rateLimiter.tryAcquire(bucket, clientId(request), limitPerMinute);
        if (retryAfter > 0) {
            response.setHeader(HttpHeaders.RETRY_AFTER, String.valueOf(retryAfter));
            // rendered by ApiExceptionHandler like any other API error
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Too many requests, retry in " + retryAfter + "s");
        }
        return true;
    }

    private String clientId(HttpServletRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated()
                && !(authentication instanceof AnonymousAuthenticationToken)) {
            return "user:" + authentication.getName();
        }
        return "ip:" + request.getRemoteAddr();
    }
}
