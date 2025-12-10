import { NextRequest, NextResponse } from 'next/server';
import { hemisClient } from '@/lib/hemis/client';
import { filterStudentData, validateStudentId, sanitizeStudentId } from '@/lib/hemis/filters';
import { getMockStudent } from '@/lib/hemis/mock-data';

const USE_MOCK = process.env.USE_MOCK_HEMIS === 'true';

export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const { studentId } = body;

        if (!studentId) {
            return NextResponse.json(
                { success: false, error: 'Student ID is required' },
                { status: 400 }
            );
        }

        // Validate student ID format
        if (!validateStudentId(studentId)) {
            return NextResponse.json(
                { success: false, error: 'Invalid student ID format. Must be 11-12 digits.' },
                { status: 400 }
            );
        }

        const sanitizedId = sanitizeStudentId(studentId);

        // Use mock data if enabled
        if (USE_MOCK) {
            const mockStudent = getMockStudent(sanitizedId);
            if (!mockStudent) {
                return NextResponse.json(
                    { success: false, error: 'Student not found in mock data' },
                    { status: 404 }
                );
            }

            const filteredData = filterStudentData(mockStudent);
            return NextResponse.json({
                success: true,
                data: filteredData,
                source: 'mock',
            });
        }

        // Real HEMIS API call
        const response = await hemisClient.verifyStudent(sanitizedId);

        if (!response.success || !response.data) {
            return NextResponse.json(
                {
                    success: false,
                    error: response.error || 'Student not found in HEMIS system'
                },
                { status: 404 }
            );
        }

        // Filter sensitive data before sending to client
        const filteredData = filterStudentData(response.data);

        return NextResponse.json({
            success: true,
            data: filteredData,
            source: 'hemis',
        });

    } catch (error: any) {
        console.error('Error verifying student:', error);
        return NextResponse.json(
            {
                success: false,
                error: 'Internal server error while verifying student'
            },
            { status: 500 }
        );
    }
}

// GET method for testing
export async function GET(request: NextRequest) {
    const searchParams = request.nextUrl.searchParams;
    const studentId = searchParams.get('studentId');

    if (!studentId) {
        return NextResponse.json(
            { success: false, error: 'Student ID is required' },
            { status: 400 }
        );
    }

    // Reuse POST logic
    return POST(
        new NextRequest(request.url, {
            method: 'POST',
            body: JSON.stringify({ studentId }),
        })
    );
}
