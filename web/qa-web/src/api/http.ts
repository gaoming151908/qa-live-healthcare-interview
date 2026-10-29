const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080').replace(/\/$/, '');

interface Envelope<T> {
  code: number;
  message: string;
  data: T;
}

export class ApiError extends Error {
  readonly status: number;
  readonly code: number;

  constructor(message: string, status: number, code: number) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
  }
}

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
  body?: unknown;
  token?: string | null;
}

/**
 * Thin wrapper around fetch that understands the {code,message,data} envelope
 * returned by qa-service-user and turns non-zero codes into ApiError.
 */
export async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const headers: Record<string, string> = {};
  if (options.body !== undefined) {
    headers['Content-Type'] = 'application/json';
  }
  if (options.token) {
    headers.Authorization = `Bearer ${options.token}`;
  }

  let response: Response;
  try {
    response = await fetch(`${API_BASE_URL}/api${path}`, {
      method: options.method ?? 'GET',
      headers,
      body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    });
  } catch {
    throw new ApiError('无法连接后端服务，请确认 qa-service-user 已启动', 0, -1);
  }

  let envelope: Envelope<T> | null = null;
  try {
    envelope = (await response.json()) as Envelope<T>;
  } catch {
    // Non-JSON response (e.g. gateway error) is reported below.
  }

  if (!response.ok || !envelope || envelope.code !== 0) {
    throw new ApiError(
      envelope?.message || `请求失败 (HTTP ${response.status})`,
      response.status,
      envelope?.code ?? response.status,
    );
  }

  return envelope.data;
}

export { API_BASE_URL };
