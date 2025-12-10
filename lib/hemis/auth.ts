/**
 * HEMIS Student API Authentication
 * Two-step authentication: auth/login → account/me
 */

export interface HemisLoginRequest {
    login: string;
    password: string;
}

export interface HemisStudent {
    id: string;
    uuid?: string;
    name?: string;
    full_name?: string;
    first_name?: string;
    second_name?: string;
    third_name?: string;
    short_name?: string;
    login: string;
    email: string;
    phone?: string;
    university_id?: string;
    university?: string;
    picture?: string;
    image?: string;
    student_id_number?: string;
    type?: string;
    [key: string]: any; // Allow additional fields from HEMIS
}

export interface HemisLoginResponse {
    success: boolean;
    data?: {
        token: string;
        expires_in: number;
        student: HemisStudent;
    };
    error?: string;
}

const HEMIS_STUDENT_API_URL = process.env.HEMIS_STUDENT_API_URL || 'https://student.umft.uz/rest/v1/';

/**
 * Login to HEMIS Student API
 * Step 1: Get JWT token from auth/login
 * Step 2: Get student data from account/me using the token
 */
export async function hemisLogin(login: string, password: string): Promise<HemisLoginResponse> {
    try {
        console.log('[HEMIS Auth] Step 1: Getting JWT token from auth/login');

        // Step 1: Get JWT token
        const loginResponse = await fetch(`${HEMIS_STUDENT_API_URL}auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ login, password }),
        });

        const loginText = await loginResponse.text();
        console.log('[HEMIS Auth] Login response status:', loginResponse.status);
        console.log('[HEMIS Auth] Login response body:', loginText);

        if (!loginResponse.ok) {
            console.error('[HEMIS Auth] Login failed');
            return {
                success: false,
                error: loginResponse.status === 401
                    ? 'Login yoki parol noto\'g\'ri'
                    : `HEMIS login failed: ${loginResponse.statusText}`,
            };
        }

        const loginData = JSON.parse(loginText);
        const token = loginData.data?.token || loginData.token;

        if (!token) {
            console.error('[HEMIS Auth] No token in response');
            return {
                success: false,
                error: 'Token olinmadi',
            };
        }

        console.log('[HEMIS Auth] ✓ JWT token received');
        console.log('[HEMIS Auth] Step 2: Getting student data from account/me');

        // Step 2: Get student data
        const meResponse = await fetch(`${HEMIS_STUDENT_API_URL}account/me`, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`,
            },
        });

        const meText = await meResponse.text();
        console.log('[HEMIS Auth] Account/me response status:', meResponse.status);
        console.log('[HEMIS Auth] Account/me response body:', meText);

        if (!meResponse.ok) {
            console.error('[HEMIS Auth] Failed to get student data');
            return {
                success: false,
                error: 'Student ma\'lumotlari olinmadi',
            };
        }

        const meData = JSON.parse(meText);
        console.log('[HEMIS Auth] ✓ Login successful');

        return {
            success: true,
            data: {
                token,
                expires_in: loginData.data?.expires_in || 172800,
                student: meData.data || meData,
            },
        };
    } catch (error) {
        console.error('[HEMIS Auth] Error:', error);
        return {
            success: false,
            error: error instanceof Error ? error.message : 'Unknown error',
        };
    }
}

/**
 * Get student info using HEMIS JWT token
 */
export async function getHemisStudentInfo(token: string): Promise<HemisLoginResponse> {
    try {
        console.log('[HEMIS Auth] Fetching student info');

        const response = await fetch(`${HEMIS_STUDENT_API_URL}account/me`, {
            headers: {
                'Authorization': `Bearer ${token}`,
            },
        });

        if (!response.ok) {
            console.error('[HEMIS Auth] Failed to get student info:', response.status);
            return {
                success: false,
                error: 'Failed to get student info',
            };
        }

        const data = await response.json();
        console.log('[HEMIS Auth] ✓ Student info retrieved');

        return {
            success: true,
            data: {
                token,
                expires_in: 172800,
                student: data.data || data,
            },
        };
    } catch (error) {
        console.error('[HEMIS Auth] Error:', error);
        return {
            success: false,
            error: error instanceof Error ? error.message : 'Unknown error',
        };
    }
}

/**
 * Refresh HEMIS token
 */
export async function refreshHemisToken(token: string): Promise<HemisLoginResponse> {
    try {
        console.log('[HEMIS Auth] Refreshing token');

        const response = await fetch(`${HEMIS_STUDENT_API_URL}auth/refresh-token`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
            },
        });

        if (!response.ok) {
            console.error('[HEMIS Auth] Token refresh failed:', response.status);
            return {
                success: false,
                error: 'Token refresh failed',
            };
        }

        const data = await response.json();
        console.log('[HEMIS Auth] ✓ Token refreshed');

        return {
            success: true,
            data: {
                token: data.data?.token || data.token,
                expires_in: data.data?.expires_in || 172800,
                student: data.data?.student || data.student,
            },
        };
    } catch (error) {
        console.error('[HEMIS Auth] Error:', error);
        return {
            success: false,
            error: error instanceof Error ? error.message : 'Unknown error',
        };
    }
}
