package com.lonwulf.sudoku.security;

import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
public class AuthUtil {
    private final IUserRepository userRepository;

    public AuthUtil(IUserRepository userRepository) {
        this.userRepository = userRepository;
    }

    private String getUserId(Authentication authentication){
        Jwt jwt = (Jwt) authentication.getPrincipal();
        return jwt.getClaimAsString("sub"); //google userId
    }

    private String getEmail(Authentication authentication){
        Jwt jwt = (Jwt) authentication.getPrincipal();
        return jwt.getClaimAsString("email");
    }
    private String getDisplayName(Authentication authentication){
        Jwt jwt = (Jwt) authentication.getPrincipal();
        // google might put "name" or "given_name"/"family_name"
        String name = jwt.getClaimAsString("name");
        if (name == null) name = jwt.getClaimAsString("given_name");
        return name;
    }

    @Transactional
    public User ensureUserExists(Authentication authentication){
        String userId = getUserId(authentication);
        return userRepository.findById(userId).orElseGet(() -> {
           User user = new User();
            user.setId(userId);
            user.setEmail(getEmail(authentication));
            user.setDisplayName(getDisplayName(authentication));
            user.setLifetimeScore(0);
            user.setPuzzlesCompleted(0);
            return userRepository.save(user);
        });
    }
}
