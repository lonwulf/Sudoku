package com.lonwulf.sudoku.security;

import com.lonwulf.sudoku.data.entity.User;
import com.lonwulf.sudoku.data.repository.IUserRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

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

    // Not @Transactional on purpose: the insert runs in its own transaction so a lost race
    // (two first requests from the same new user) can be caught and the winner's row read back
    public User ensureUserExists(Authentication authentication){
        String userId = getUserId(authentication);
        return userRepository.findById(userId).orElseGet(() -> {
            User user = new User(userId);
            user.setEmail(getEmail(authentication));
            user.setDisplayName(getDisplayName(authentication));
            user.setLifetimeScore(0);
            user.setPuzzlesCompleted(0);
            try {
                return userRepository.saveAndFlush(user);
            } catch (DataIntegrityViolationException e) {
                return userRepository.findById(userId).orElseThrow(() -> e);
            }
        });
    }
}
