package com.leansofx.qaserviceuser.service;

import com.leansofx.qaserviceuser.common.BusinessException;
import com.leansofx.qaserviceuser.dto.DoctorDto;
import com.leansofx.qaserviceuser.entity.Doctor;
import com.leansofx.qaserviceuser.repository.DoctorRepository;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class DoctorService {

    private final DoctorRepository doctorRepository;
    private final PasswordEncoder passwordEncoder;

    public DoctorService(DoctorRepository doctorRepository, PasswordEncoder passwordEncoder) {
        this.doctorRepository = doctorRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public List<DoctorDto> listDoctors(boolean activeOnly) {
        return doctorRepository.findAll(Sort.by(Sort.Direction.ASC, "id")).stream()
                .filter(doctor -> !activeOnly || doctor.isActive())
                .map(this::toDto)
                .toList();
    }

    public DoctorDto getDoctor(String id) {
        Doctor doctor = doctorRepository.findById(id)
                .orElseThrow(() -> BusinessException.notFound("医生不存在: " + id));
        return toDto(doctor);
    }

    public DoctorDto login(String username, String rawPassword) {
        Doctor doctor = doctorRepository.findByUsername(username)
                .orElseThrow(() -> BusinessException.unauthorized("用户名或密码错误"));
        if (!passwordEncoder.matches(rawPassword, doctor.getPassword())) {
            throw BusinessException.unauthorized("用户名或密码错误");
        }
        return toDto(doctor);
    }

    private DoctorDto toDto(Doctor doctor) {
        return new DoctorDto(
                doctor.getId(),
                doctor.getUsername(),
                doctor.getName(),
                doctor.getTitle(),
                doctor.getDepartment(),
                doctor.getAvatar(),
                doctor.getExperience(),
                doctor.getSpecialties(),
                doctor.isActive()
        );
    }
}
