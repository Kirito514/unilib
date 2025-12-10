'use client';

import { useEffect, useState } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import Barcode from 'react-barcode';

interface QRBarcodeCardProps {
    studentNumber: string;
    studentName: string;
}

export default function QRBarcodeCard({ studentNumber, studentName }: QRBarcodeCardProps) {
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    if (!mounted || !studentNumber) return null;

    return (
        <div className="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg border border-gray-200 dark:border-gray-700">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-6">
                Student ID
            </h3>

            <div className="space-y-6">
                {/* QR Code */}
                <div className="flex flex-col items-center">
                    <div className="bg-white p-4 rounded-xl">
                        <QRCodeSVG
                            value={studentNumber}
                            size={200}
                            level="H"
                            includeMargin={true}
                        />
                    </div>
                    <p className="mt-3 text-sm text-gray-600 dark:text-gray-400">
                        QR Code
                    </p>
                </div>

                {/* Barcode */}
                <div className="flex flex-col items-center">
                    <div className="bg-white p-4 rounded-xl">
                        <Barcode
                            value={studentNumber}
                            width={2}
                            height={80}
                            displayValue={true}
                            fontSize={14}
                        />
                    </div>
                    <p className="mt-3 text-sm text-gray-600 dark:text-gray-400">
                        Barcode
                    </p>
                </div>

                {/* Student Info */}
                <div className="pt-4 border-t border-gray-200 dark:border-gray-700">
                    <p className="text-sm text-gray-600 dark:text-gray-400">Student Number</p>
                    <p className="text-lg font-semibold text-gray-900 dark:text-white mt-1">
                        {studentNumber}
                    </p>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-2">Name</p>
                    <p className="text-base font-medium text-gray-900 dark:text-white mt-1">
                        {studentName}
                    </p>
                </div>
            </div>
        </div>
    );
}
