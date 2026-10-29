import { request } from './http';

export interface PatientApiModel {
  id: number;
  username: string;
  name: string;
  birthday: string | null;
  phone: string | null;
  gender: string | null;
}

export interface AuthResult {
  token: string;
  patient: PatientApiModel;
}

export interface RegisterPayload {
  username: string;
  password: string;
  name: string;
  birthday?: string | null;
  phone?: string | null;
  gender?: string | null;
}

export function loginPatient(username: string, password: string): Promise<AuthResult> {
  return request<AuthResult>('/patients/login', {
    method: 'POST',
    body: { username, password },
  });
}

export function registerPatient(payload: RegisterPayload): Promise<AuthResult> {
  return request<AuthResult>('/patients/register', {
    method: 'POST',
    body: payload,
  });
}

export function fetchCurrentPatient(token: string): Promise<PatientApiModel> {
  return request<PatientApiModel>('/patients/me', { token });
}
