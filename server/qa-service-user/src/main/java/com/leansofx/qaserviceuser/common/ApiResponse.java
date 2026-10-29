package com.leansofx.qaserviceuser.common;

/**
 * Unified response envelope used by every public API of qa-service-user.
 *
 * <p>{@code code} is {@code 0} for success and a business error code otherwise.
 * HTTP status codes still carry the transport-level semantics (200/201/400/401/404/409/500).</p>
 */
public record ApiResponse<T>(int code, String message, T data) {

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(0, "success", data);
    }

    public static <T> ApiResponse<T> ok(String message, T data) {
        return new ApiResponse<>(0, message, data);
    }

    public static <T> ApiResponse<T> error(int code, String message) {
        return new ApiResponse<>(code, message, null);
    }
}
