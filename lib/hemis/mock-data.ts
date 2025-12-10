/**
 * Mock HEMIS data for testing without real API
 */

export const mockStudents = {
    '12345678901': {
        student_id_number: '12345678901',
        first_name: 'Alisher',
        second_name: 'Navoiy',
        third_name: 'Ahmadovich',
        email: 'alisher.navoiy@student.umft.uz',
        phone: '+998901234567',
        group: {
            name: '101-guruh',
        },
        department: {
            id: '001',
            name: 'Dasturiy injiniring',
            code: '001',
        },
        faculty: {
            name: 'Informatika fakulteti',
        },
        specialty: {
            name: 'Dasturiy injiniring',
            code: '5140900',
        },
        education_year: {
            name: '2023-2024',
        },
        education_type: {
            name: 'Bakalavr',
        },
        education_form: {
            name: 'Kunduzgi',
        },
    },
    '98765432109': {
        student_id_number: '98765432109',
        first_name: 'Nodira',
        second_name: 'Begim',
        third_name: 'Karimovna',
        email: 'nodira.begim@student.umft.uz',
        phone: '+998909876543',
        group: {
            name: '102-guruh',
        },
        department: {
            id: '002',
            name: 'Axborot xavfsizligi',
            code: '002',
        },
        faculty: {
            name: 'Informatika fakulteti',
        },
        specialty: {
            name: 'Axborot xavfsizligi',
            code: '5140800',
        },
        education_year: {
            name: '2023-2024',
        },
        education_type: {
            name: 'Bakalavr',
        },
        education_form: {
            name: 'Kunduzgi',
        },
    },
};

export function getMockStudent(studentId: string) {
    return mockStudents[studentId as keyof typeof mockStudents] || null;
}
