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

    // Principals are JWTs, except for the dev profile's basic-auth users
    private String getUserId(Authentication authentication){
        if (authentication.getPrincipal() instanceof Jwt jwt) {
            return jwt.getClaimAsString("sub"); //google userId
        }
        return authentication.getName();
    }

    private String getEmail(Authentication authentication){
        if (authentication.getPrincipal() instanceof Jwt jwt) {
            return jwt.getClaimAsString("email");
        }
        return null;
    }
    private String getDisplayName(Authentication authentication){
        if (!(authentication.getPrincipal() instanceof Jwt jwt)) {
            return authentication.getName();
        }
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
