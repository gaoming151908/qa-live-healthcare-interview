import { request } from './http';

export interface DoctorApiModel {
  id: string;
  username: string;
  name: string;
  title: string;
  department: string;
  avatar: string;
  experience: string;
  specialties: string[];
  isActive: boolean;
}

export function fetchDoctors(activeOnly = false): Promise<DoctorApiModel[]> {
  return request<DoctorApiModel[]>(`/doctors${activeOnly ? '?activeOnly=true' : ''}`);
}

export function loginDoctor(username: string, password: string): Promise<DoctorApiModel> {
  return request<DoctorApiModel>('/doctors/login', {
    method: 'POST',
    body: { username, password },
  });
}
