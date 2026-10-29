package com.leansofx.qaserviceuser.controller;

import com.leansofx.qaserviceuser.common.ApiResponse;
import com.leansofx.qaserviceuser.dto.DoctorDto;
import com.leansofx.qaserviceuser.dto.DoctorLoginRequest;
import com.leansofx.qaserviceuser.service.DoctorService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/doctors")
public class DoctorController {

    private final DoctorService doctorService;

    public DoctorController(DoctorService doctorService) {
        this.doctorService = doctorService;
    }

    /**
     * Doctor list consumed by the front-end doctors page (and the home page's open rooms).
     *
     * @param activeOnly when true only doctors with {@code is_active = 1} are returned
     */
    @GetMapping
    public ApiResponse<List<DoctorDto>> listDoctors(
            @RequestParam(name = "activeOnly", defaultValue = "false") boolean activeOnly) {
        return ApiResponse.ok(doctorService.listDoctors(activeOnly));
    }

    @GetMapping("/{id}")
    public ApiResponse<DoctorDto> getDoctor(@PathVariable String id) {
        return ApiResponse.ok(doctorService.getDoctor(id));
    }

    @PostMapping("/login")
    public ApiResponse<DoctorDto> login(@Valid @RequestBody DoctorLoginRequest request) {
        return ApiResponse.ok("登录成功", doctorService.login(request.username(), request.password()));
    }
}
