package com.leansofx.qaserviceuser.service;

import com.leansofx.qaserviceuser.common.BusinessException;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class JwtServiceTest {

    private final JwtService jwtService =
            new JwtService("qa-live-healthcare-interview-test-secret-key-2025", 3600000);

    @Test
    void generatedTokenCanBeParsedBack() {
        String token = jwtService.generateToken(42L, "zhaoming");
        assertEquals(42L, jwtService.parsePatientId(token));
    }

    @Test
    void tamperedTokenIsRejected() {
        String token = jwtService.generateToken(42L, "zhaoming");
        String tampered = token.substring(0, token.length() - 2) + "xx";
        assertThrows(BusinessException.class, () -> jwtService.parsePatientId(tampered));
    }

    @Test
    void malformedTokenIsRejected() {
        assertThrows(BusinessException.class, () -> jwtService.parsePatientId("not-a-jwt"));
    }

    @Test
    void shortSecretIsRejected() {
        assertThrows(IllegalArgumentException.class, () -> new JwtService("too-short", 1000));
    }
}
