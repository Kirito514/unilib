/**
 * Data filtering functions for HEMIS API responses
 * Ensures only necessary data is exposed to the client
 */

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

interface FilteredStudentData {
    studentId: string;
    fullName: string;
    email?: string;
    department?: string;
    departmentCode?: string;
    group?: string;
    faculty?: string;
    specialty?: string;
    educationYear?: string;
    educationType?: string;
    educationForm?: string;
}

/**
 * Filter student data to only include safe, necessary fields
 */
export function filterStudentData(student: HemisStudent): FilteredStudentData {
    const fullName = [
        student.second_name,
        student.first_name,
        student.third_name,
    ]
        .filter(Boolean)
        .join(' ');

    return {
        studentId: student.student_id_number,
        fullName,
        email: student.email,
        department: student.department?.name,
        departmentCode: student.department?.code,
        group: student.group?.name,
        faculty: student.faculty?.name,
        specialty: student.specialty?.name,
        educationYear: student.education_year?.name,
        educationType: student.education_type?.name,
        educationForm: student.education_form?.name,
    };
}

/**
 * Sanitize student ID (remove non-numeric characters)
 */
export function sanitizeStudentId(studentId: string): string {
    return studentId.replace(/\D/g, '');
}

/**
 * Validate student ID format
 */
export function validateStudentId(studentId: string): boolean {
    const sanitized = sanitizeStudentId(studentId);
    // HEMIS student IDs are typically 11-12 digits
    return (sanitized.length === 11 || sanitized.length === 12) && /^\d+$/.test(sanitized);
}
