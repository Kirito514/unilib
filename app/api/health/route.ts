import { NextResponse } from 'next/server';

export async function GET() {
    try {
        return NextResponse.json(
            {
                status: 'healthy',
                timestamp: new Date().toISOString(),
                service: 'UniLib2',
                version: '1.0.0',
            },
            { status: 200 }
        );
    } catch (error) {
        return NextResponse.json(
            {
                status: 'unhealthy',
                error: error instanceof Error ? error.message : 'Unknown error',
                timestamp: new Date().toISOString(),
            },
            { status: 503 }
        );
    }
}
