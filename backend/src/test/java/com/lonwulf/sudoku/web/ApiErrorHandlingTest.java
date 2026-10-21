package com.lonwulf.sudoku.web;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class ApiErrorHandlingTest {
    @Autowired
    private MockMvc mockMvc;

    @Test
    void outOfRangeParamIsBadRequestNamingTheParam() throws Exception {
        mockMvc.perform(get("/leaderboard").param("size", "1000").with(user("player")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value("error"))
                .andExpect(jsonPath("$.message", containsString("size")));
    }

    @Test
    void auditLimitOfZeroIsBadRequest() throws Exception {
        mockMvc.perform(get("/admin/audit/recent").param("limit", "0").with(user("boss").roles("ADMIN")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("limit")));
    }

    @Test
    void unknownUserIsNotFound() throws Exception {
        mockMvc.perform(post("/admin/unban/nobody").with(user("boss").roles("ADMIN")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value("error"))
                .andExpect(jsonPath("$.message").value("Not found"));
    }

    @Test
    void responseStatusExceptionKeepsItsReason() throws Exception {
        mockMvc.perform(get("/api/v1/sudoku/puzzle").param("difficulty", "foo"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("difficulty must be one of")));
    }

    @Test
    void malformedJsonIsBadRequest() throws Exception {
        mockMvc.perform(post("/api/v1/sudoku/puzzle/x/submit").with(user("player"))
                        .contentType(MediaType.APPLICATION_JSON).content("{oops"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value("error"));
    }

    @Test
    void securityErrorsAreNotSwallowed() throws Exception {
        mockMvc.perform(post("/admin/unban/nobody").with(user("player")))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/scores/my_score"))
                .andExpect(status().isUnauthorized());
    }
}
