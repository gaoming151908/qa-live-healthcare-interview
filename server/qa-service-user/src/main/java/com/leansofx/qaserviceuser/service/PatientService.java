package com.leansofx.qaserviceuser.service;

import com.leansofx.qaserviceuser.common.BusinessException;
import com.leansofx.qaserviceuser.dto.AuthResponse;
import com.leansofx.qaserviceuser.dto.PatientDto;
import com.leansofx.qaserviceuser.dto.PatientLoginRequest;
import com.leansofx.qaserviceuser.dto.PatientRegisterRequest;
import com.leansofx.qaserviceuser.entity.Patient;
import com.leansofx.qaserviceuser.repository.PatientRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PatientService {

    private final PatientRepository patientRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public PatientService(PatientRepository patientRepository,
                          PasswordEncoder passwordEncoder,
                          JwtService jwtService) {
        this.patientRepository = patientRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public AuthResponse register(PatientRegisterRequest request) {
        if (patientRepository.existsByUsername(request.username())) {
            throw BusinessException.conflict("用户名已被占用: " + request.username());
        }
        Patient patient = new Patient();
        patient.setUsername(request.username());
        patient.setPassword(passwordEncoder.encode(request.password()));
        patient.setName(request.name());
        patient.setBirthday(request.birthday());
        patient.setPhone(request.phone());
        patient.setGender(request.gender());
        Patient saved = patientRepository.save(patient);
        return new AuthResponse(jwtService.generateToken(saved.getId(), saved.getUsername()), toDto(saved));
    }

    @Transactional(readOnly = true)
    public AuthResponse login(PatientLoginRequest request) {
        Patient patient = patientRepository.findByUsername(request.username())
                .orElseThrow(() -> BusinessException.unauthorized("用户名或密码错误"));
        if (!passwordEncoder.matches(request.password(), patient.getPassword())) {
            throw BusinessException.unauthorized("用户名或密码错误");
        }
        return new AuthResponse(jwtService.generateToken(patient.getId(), patient.getUsername()), toDto(patient));
    }

    @Transactional(readOnly = true)
    public PatientDto getCurrentPatient(String token) {
        Long patientId = jwtService.parsePatientId(token);
        Patient patient = patientRepository.findById(patientId)
                .orElseThrow(() -> BusinessException.unauthorized("账号不存在或已被删除"));
        return toDto(patient);
    }

    private PatientDto toDto(Patient patient) {
        return new PatientDto(
                patient.getId(),
                patient.getUsername(),
                patient.getName(),
                patient.getBirthday(),
                patient.getPhone(),
                patient.getGender()
        );
    }
}
