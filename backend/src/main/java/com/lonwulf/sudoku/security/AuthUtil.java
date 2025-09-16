package com.lonwulf.sudoku.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

@Component
public class AuthUtil {
    public String getUserId(Authentication authentication){
        Jwt jwt = (Jwt) authentication.getPrincipal();
        return jwt.getClaimAsString("sub"); //google userId
    }

    public String getEmail(Authentication authentication){
        Jwt jwt = (Jwt) authentication.getPrincipal();
        return jwt.getClaimAsString("email");
    }
    public String getDisplayName(Authentication authentication){
        Jwt jwt = (Jwt) authentication.getPrincipal();
        // google might put "name" or "given_name"/"family_name"
        String name = jwt.getClaimAsString("name");
        if (name == null) name = jwt.getClaimAsString("given_name");
        return name;
    }
}
