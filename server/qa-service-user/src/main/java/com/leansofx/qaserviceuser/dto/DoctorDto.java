package com.leansofx.qaserviceuser.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * Doctor view model. The password hash is deliberately not part of this contract.
 */
public record DoctorDto(
        String id,
        String username,
        String name,
        String title,
        String department,
        String avatar,
        String experience,
        List<String> specialties,
        @JsonProperty("isActive") boolean isActive
) {
}
