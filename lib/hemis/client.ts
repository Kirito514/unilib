/**
 * HEMIS API Client for UMFT
 * Handles communication with the HEMIS (Higher Education Management Information System)
 */

interface HemisConfig {
    baseUrl: string;
    apiKey: string;
    timeout?: number;
}

interface HemisStudent {
    student_id_number: string;
    first_name: string;
    second_name: string;
    third_name: string;
    email?: string;
    phone?: string;
    group?: {
        name: string;
    };
    department?: {
        id: string;
        name: string;
        code?: string;
    };
    faculty?: {
        name: string;
    };
    specialty?: {
        name: string;
        code?: string;
    };
    education_year?: {
        name: string;
    };
    education_type?: {
        name: string;
    };
    education_form?: {
        name: string;
    };
}

interface HemisApiResponse<T> {
    success: boolean;
    data?: T;
    error?: string;
}

export class HemisApiClient {
    private config: HemisConfig;

    constructor(config: Partial<HemisConfig> = {}) {
        this.config = {
            baseUrl: config.baseUrl || process.env.NEXT_PUBLIC_HEMIS_API_URL || 'https://student.umft.uz/rest/v1/',
            apiKey: config.apiKey || process.env.HEMIS_API_KEY || '',
            timeout: config.timeout || 10000,
            ...config
        };

        if (!this.config.apiKey) {
            console.warn('HEMIS API key not configured');
        }
    }

    /**
     * Make a request to HEMIS API
     */
    private async request<T>(endpoint: string, options: RequestInit = {}): Promise<HemisApiResponse<T>> {
        const url = `${this.config.baseUrl}${endpoint}`;

        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), this.config.timeout);

            const response = await fetch(url, {
                ...options,
                headers: {
                    'Authorization': `Bearer ${this.config.apiKey}`,
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    ...options.headers,
                },
                signal: controller.signal,
            });

            clearTimeout(timeoutId);

            if (!response.ok) {
                throw new Error(`HEMIS API error: ${response.status} ${response.statusText}`);
            }

            const data = await response.json();

            return {
                success: true,
                data: data.data || data,
            };
        } catch (error: any) {
            console.error('HEMIS API request failed:', error);
            return {
                success: false,
                error: error.message || 'Unknown error occurred',
            };
        }
    }

    /**
     * Verify student by ID number
     */
    async verifyStudent(studentId: string): Promise<HemisApiResponse<HemisStudent>> {
        console.log(`[HEMIS] Searching for student: ${studentId}`);

        // HEMIS API returns all students, we need to filter
        const response = await this.request<any>('data/student-list');

        if (!response.success || !response.data) {
            console.log(`[HEMIS] API request failed:`, response.error);
            return {
                success: false,
                error: response.error || 'Failed to fetch student list',
            };
        }

        // Handle response structure: {data: {items: [...], pagination: {...}}}
        const items = response.data.items || response.data;

        if (!Array.isArray(items)) {
            console.log(`[HEMIS] Unexpected response format`);
            return {
                success: false,
                error: 'Unexpected API response format',
            };
        }

        // Find student by ID
        const student = items.find((s: any) => s.student_id_number === studentId);

        if (!student) {
            console.log(`[HEMIS] Student not found in ${items.length} records`);
            // Debug: Show first 5 student IDs to help identify format
            console.log('[HEMIS] Sample IDs from API:', items.slice(0, 5).map((s: any) => s.student_id_number));
            return {
                success: false,
                error: 'Student not found in HEMIS system',
            };
        }

        console.log(`[HEMIS] ✓ Student found:`, student.first_name, student.second_name);
        return {
            success: true,
            data: student,
        };
    }

    /**
     * Get student data by ID
     */
    async getStudentData(studentId: string): Promise<HemisApiResponse<HemisStudent>> {
        return this.request<HemisStudent>(`student/${studentId}`);
    }

    /**
     * Get list of students (if endpoint supports it)
     */
    async getStudentList(params?: Record<string, any>): Promise<HemisApiResponse<HemisStudent[]>> {
        const queryString = params ? '?' + new URLSearchParams(params).toString() : '';
        return this.request<HemisStudent[]>(`student-list${queryString}`);
    }
}

// Export singleton instance
export const hemisClient = new HemisApiClient();
