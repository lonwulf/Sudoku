package com.lonwulf.sudoku.web;

import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.lang.Nullable;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.util.Map;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

/**
 * Gives every API error the same {"status": "error", "message": ...} body the controllers return.
 * Security exceptions are deliberately not handled here so they keep their 401/403.
 */
@RestControllerAdvice
public class ApiExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(NoSuchElementException.class)
    public ResponseEntity<Object> handleNotFound(NoSuchElementException ex, WebRequest request) {
        return handleExceptionInternal(ex, errorBody("Not found"), new HttpHeaders(), HttpStatus.NOT_FOUND, request);
    }

    // e.g. Redis or the database is unreachable: a temporary outage, not a bug
    @ExceptionHandler(DataAccessResourceFailureException.class)
    public ResponseEntity<Object> handleUnavailable(DataAccessResourceFailureException ex, WebRequest request) {
        logger.error("Backing store unavailable", ex);
        return handleExceptionInternal(ex, errorBody("Service temporarily unavailable, please retry"),
                new HttpHeaders(), HttpStatus.SERVICE_UNAVAILABLE, request);
    }

    @Override
    protected ResponseEntity<Object> handleHandlerMethodValidationException(
            HandlerMethodValidationException ex, HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        // e.g. "size must be less than or equal to 100"
        String message = ex.getParameterValidationResults().stream()
                .flatMap(result -> result.getResolvableErrors().stream()
                        .map(error -> result.getMethodParameter().getParameterName() + " " + error.getDefaultMessage()))
                .collect(Collectors.joining("; "));
        return handleExceptionInternal(ex, errorBody(message), headers, status, request);
    }

    @Override
    protected ResponseEntity<Object> handleExceptionInternal(
            Exception ex, @Nullable Object body, HttpHeaders headers, HttpStatusCode statusCode, WebRequest request) {
        // framework exceptions arrive with a ProblemDetail body, or none; their detail is client-safe,
        // e.g. ResponseStatusException's reason or "Failed to read request"
        if (body == null || body instanceof ProblemDetail) {
            String detail = body instanceof ProblemDetail problemDetail ? problemDetail.getDetail()
                    : ex instanceof ErrorResponse errorResponse ? errorResponse.getBody().getDetail() : null;
            body = errorBody(detail != null ? detail : HttpStatus.valueOf(statusCode.value()).getReasonPhrase());
        }
        return super.handleExceptionInternal(ex, body, headers, statusCode, request);
    }

    private Map<String, Object> errorBody(String message) {
        return Map.of("status", "error", "message", message);
    }
}
