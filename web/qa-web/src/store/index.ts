import { reactive } from 'vue';
import questionData from '../data/question-list.json';
import {
  fetchDoctors,
  loginDoctor as loginDoctorRequest,
  type DoctorApiModel,
} from '../api/doctor';
import {
  fetchCurrentPatient,
  loginPatient as loginPatientRequest,
  registerPatient as registerPatientRequest,
  type PatientApiModel,
  type RegisterPayload,
} from '../api/patient';

export interface Doctor {
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

export interface Patient {
  id: number;
  username: string;
  name: string;
  birthday: string | null;
  phone: string | null;
  gender: string | null;
}

export interface Question {
  id: string;
  patientId: string;
  patientName: string;
  doctorId: string;
  doctorName: string;
  question: string;
  submitTime: string;
  status: 'pending' | 'answered';
  answer: string | null;
  answerTime: string | null;
}

interface State {
  doctors: Doctor[];
  questions: Question[];
  currentDoctor: Doctor | null;
  currentPatient: Patient | null;
  patientToken: string | null;
  doctorsLoading: boolean;
  doctorsError: string | null;
}

const TOKEN_STORAGE_KEY = 'qa-patient-token';
const PATIENT_STORAGE_KEY = 'qa-patient-profile';

function readStorage(key: string): string | null {
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
}

function readStoredPatient(): Patient | null {
  const raw = readStorage(PATIENT_STORAGE_KEY);
  if (!raw) {
    return null;
  }
  try {
    return JSON.parse(raw) as Patient;
  } catch {
    return null;
  }
}

function writeStorage(key: string, value: string | null) {
  try {
    if (value === null) {
      localStorage.removeItem(key);
    } else {
      localStorage.setItem(key, value);
    }
  } catch {
    // Storage can be unavailable in private mode; the in-memory session still works.
  }
}

function mapDoctor(dto: DoctorApiModel): Doctor {
  return {
    id: dto.id,
    username: dto.username,
    name: dto.name,
    title: dto.title,
    department: dto.department,
    avatar: dto.avatar,
    experience: dto.experience,
    specialties: dto.specialties ?? [],
    isActive: dto.isActive,
  };
}

function mapPatient(dto: PatientApiModel): Patient {
  return {
    id: dto.id,
    username: dto.username,
    name: dto.name,
    birthday: dto.birthday,
    phone: dto.phone,
    gender: dto.gender,
  };
}

const storedToken = readStorage(TOKEN_STORAGE_KEY);

const state = reactive<State>({
  doctors: [],
  questions: questionData as Question[],
  currentDoctor: null,
  currentPatient: readStoredPatient(),
  patientToken: storedToken,
  doctorsLoading: false,
  doctorsError: null,
});

function applyPatientSession(token: string, patient: Patient) {
  state.patientToken = token;
  state.currentPatient = patient;
  writeStorage(TOKEN_STORAGE_KEY, token);
  writeStorage(PATIENT_STORAGE_KEY, JSON.stringify(patient));
}

function clearPatientSession() {
  state.patientToken = null;
  state.currentPatient = null;
  writeStorage(TOKEN_STORAGE_KEY, null);
  writeStorage(PATIENT_STORAGE_KEY, null);
}

export const store = {
  state,

  async loadDoctors(force = false): Promise<Doctor[]> {
    if (state.doctorsLoading) {
      return state.doctors;
    }
    if (!force && state.doctors.length > 0) {
      return state.doctors;
    }
    state.doctorsLoading = true;
    state.doctorsError = null;
    try {
      const doctors = await fetchDoctors();
      state.doctors = doctors.map(mapDoctor);
      return state.doctors;
    } catch (error) {
      state.doctorsError = error instanceof Error ? error.message : '医生数据加载失败';
      throw error;
    } finally {
      state.doctorsLoading = false;
    }
  },

  async loginDoctor(username: string, password: string): Promise<Doctor> {
    const doctor = mapDoctor(await loginDoctorRequest(username, password));
    state.currentDoctor = doctor;
    return doctor;
  },

  logoutDoctor() {
    state.currentDoctor = null;
  },

  /**
   * Restores a patient session from localStorage and validates the token against
   * GET /api/patients/me. An expired/invalid token simply results in a logged-out state.
   */
  async restorePatientSession(): Promise<void> {
    if (!state.patientToken) {
      return;
    }
    try {
      const patient = mapPatient(await fetchCurrentPatient(state.patientToken));
      state.currentPatient = patient;
      writeStorage(PATIENT_STORAGE_KEY, JSON.stringify(patient));
    } catch {
      clearPatientSession();
    }
  },

  async loginPatient(username: string, password: string): Promise<Patient> {
    const result = await loginPatientRequest(username, password);
    const patient = mapPatient(result.patient);
    applyPatientSession(result.token, patient);
    return patient;
  },

  async registerPatient(payload: RegisterPayload): Promise<Patient> {
    const result = await registerPatientRequest(payload);
    const patient = mapPatient(result.patient);
    applyPatientSession(result.token, patient);
    return patient;
  },

  logoutPatient() {
    clearPatientSession();
  },

  getQuestionsByDoctor(doctorId: string): Question[] {
    return state.questions.filter(q => q.doctorId === doctorId);
  },

  getQuestionsByPatient(patientId: string): Question[] {
    return state.questions.filter(q => q.patientId === patientId);
  },

  addQuestion(question: Omit<Question, 'id' | 'submitTime' | 'status' | 'answer' | 'answerTime'>): Question {
    const newQuestion: Question = {
      ...question,
      id: `q${Date.now()}`,
      submitTime: new Date().toISOString(),
      status: 'pending',
      answer: null,
      answerTime: null,
    };
    state.questions.push(newQuestion);
    return newQuestion;
  },

  answerQuestion(questionId: string, answer: string) {
    const question = state.questions.find(q => q.id === questionId);
    if (question) {
      question.status = 'answered';
      question.answer = answer;
      question.answerTime = new Date().toISOString();
    }
  },

  markQuestionAsAnswered(questionId: string) {
    const question = state.questions.find(q => q.id === questionId);
    if (question) {
      question.status = 'answered';
      question.answer = '已口述解答';
      question.answerTime = new Date().toISOString();
    }
  },

  getDoctorByUsername(username: string): Doctor | undefined {
    return state.doctors.find(d => d.username === username);
  },

  getActiveDoctors(): Doctor[] {
    return state.doctors.filter(d => d.isActive);
  },

  getStatistics() {
    return {
      totalDoctors: state.doctors.length,
      totalQuestions: state.questions.length,
      activeSessions: state.questions.filter(q => q.status === 'pending').length,
      totalSessions: state.doctors.filter(d => d.isActive).length,
    };
  },
};
