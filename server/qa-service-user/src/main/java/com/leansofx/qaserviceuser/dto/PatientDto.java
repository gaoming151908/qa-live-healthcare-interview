package com.leansofx.qaserviceuser.dto;

import java.time.LocalDate;

public record PatientDto(
        Long id,
        String username,
        String name,
        LocalDate birthday,
        String phone,
        String gender
) {
}
