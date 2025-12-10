'use client';

import { useState, useEffect } from 'react';

interface StudentIDCardProps {
    studentNumber: string;
}

export default function StudentIDCard({ studentNumber }: StudentIDCardProps) {
    const [qrCodeUrl, setQrCodeUrl] = useState('');
    const [barcodeUrl, setBarcodeUrl] = useState('');
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        const generateCodes = async () => {
            if (!studentNumber) return;

            // Check cache first
            const qrCacheKey = `qr-${studentNumber}`;
            const barcodeCacheKey = `barcode-${studentNumber}`;

            const qrCached = localStorage.getItem(qrCacheKey);
            const barcodeCached = localStorage.getItem(barcodeCacheKey);

            if (qrCached && barcodeCached) {
                setQrCodeUrl(qrCached);
                setBarcodeUrl(barcodeCached);
                setIsLoading(false);
                return;
            }

            try {
                // Generate QR Code
                if (!qrCached) {
                    const QRCode = (await import('qrcode')).default;
                    const qrDataUrl = await QRCode.toDataURL(`STUDENT-${studentNumber}`, {
                        width: 200,
                        margin: 2,
                    });
                    setQrCodeUrl(qrDataUrl);
                    localStorage.setItem(qrCacheKey, qrDataUrl);
                } else {
                    setQrCodeUrl(qrCached);
                }

                // Generate Barcode
                if (!barcodeCached) {
                    const JsBarcode = (await import('jsbarcode')).default;
                    const canvas = document.createElement('canvas');
                    JsBarcode(canvas, studentNumber, {
                        format: 'CODE128',
                        width: 2,
                        height: 80,
                        displayValue: true,
                    });
                    const barcodeDataUrl = canvas.toDataURL();
                    setBarcodeUrl(barcodeDataUrl);
                    localStorage.setItem(barcodeCacheKey, barcodeDataUrl);
                } else {
                    setBarcodeUrl(barcodeCached);
                }
            } catch (error) {
                console.error('Error generating codes:', error);
            } finally {
                setIsLoading(false);
            }
        };

        generateCodes();
    }, [studentNumber]);

    if (!studentNumber) return null;

    return (
        <div className="bg-gradient-to-br from-blue-500/10 to-purple-500/5 border border-blue-500/20 rounded-2xl p-6 shadow-xl">
            <h3 className="font-bold mb-4 text-base">Talaba ID</h3>

            {isLoading ? (
                <div className="flex items-center justify-center py-12">
                    <div className="w-8 h-8 border-4 border-primary/30 border-t-primary rounded-full animate-spin" />
                </div>
            ) : (
                <>
                    {/* QR Code */}
                    {qrCodeUrl && (
                        <div className="bg-white p-4 rounded-xl flex items-center justify-center mb-4 shadow-md">
                            <img
                                src={qrCodeUrl}
                                alt="Student QR Code"
                                className="w-48 h-48"
                            />
                        </div>
                    )}

                    {/* Barcode */}
                    {barcodeUrl && (
                        <div className="bg-white p-4 rounded-xl flex items-center justify-center mb-4 shadow-md">
                            <img
                                src={barcodeUrl}
                                alt="Student Barcode"
                                className="max-w-full h-auto"
                            />
                        </div>
                    )}

                    <div className="text-center space-y-1">
                        <p className="text-xs font-mono text-muted-foreground font-semibold">
                            ID: {studentNumber}
                        </p>
                        <p className="text-xs text-muted-foreground">
                            Kutubxonachiga ko'rsating
                        </p>
                    </div>
                </>
            )}
        </div>
    );
}
