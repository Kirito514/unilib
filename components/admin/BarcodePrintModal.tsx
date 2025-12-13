"use client";

import { useEffect, useRef } from 'react';
import JsBarcode from 'jsbarcode';
import { X, Printer } from 'lucide-react';

interface BarcodePrintModalProps {
    barcodes: string[];
    onClose: () => void;
}

export function BarcodePrintModal({ barcodes, onClose }: BarcodePrintModalProps) {
    const previewCanvasRefs = useRef<(HTMLCanvasElement | null)[]>([]);
    const printCanvasRefs = useRef<(HTMLCanvasElement | null)[]>([]);

    console.log('🎨 BarcodePrintModal received barcodes:', barcodes);
    console.log('🎨 Barcode count:', barcodes.length);

    useEffect(() => {
        // Generate barcodes optimized for Xprinter XP-635B thermal printer (57mm x 30mm)
        const generateBarcode = (canvas: HTMLCanvasElement, barcode: string) => {
            try {
                JsBarcode(canvas, barcode, {
                    format: 'CODE128',
                    width: 2,              // ✅ Wider bars for better visibility
                    height: 80,            // ✅ Very tall for easy scanning
                    displayValue: true,    // ✅ Show barcode number
                    fontSize: 18,          // ✅ Large readable font
                    margin: 2,             // ✅ Small margins
                    background: '#ffffff',
                    lineColor: '#000000',
                    textMargin: 5,         // ✅ Good space between barcode and text
                    marginTop: 2,
                    marginBottom: 2,
                    flat: true
                });
            } catch (error) {
                console.error('Barcode generation error:', error);
            }
        };

        console.log('🎨 Generating barcodes for', barcodes.length, 'items');

        // Generate for preview canvases
        barcodes.forEach((barcode, index) => {
            const canvas = previewCanvasRefs.current[index];
            if (canvas) {
                generateBarcode(canvas, barcode);
                console.log(`✅ Preview barcode ${index + 1} generated`);
            } else {
                console.warn(`⚠️ Preview canvas ${index + 1} not found`);
            }
        });

        // Generate for print canvases
        barcodes.forEach((barcode, index) => {
            const canvas = printCanvasRefs.current[index];
            if (canvas) {
                generateBarcode(canvas, barcode);
                console.log(`✅ Print barcode ${index + 1} generated`);
            } else {
                console.warn(`⚠️ Print canvas ${index + 1} not found`);
            }
        });
    }, [barcodes]);

    const handlePrint = () => {
        // Create print content with proper page breaks
        const printWindow = window.open('', '_blank');
        if (!printWindow) return;

        // Generate HTML for each barcode
        const barcodesHTML = barcodes.map((barcode, index) => {
            const canvas = printCanvasRefs.current[index];
            if (!canvas) return '';

            const dataUrl = canvas.toDataURL('image/png');
            return `
                <div class="barcode-page" style="
                    width: 57mm;
                    height: 30mm;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    page-break-after: ${index < barcodes.length - 1 ? 'always' : 'auto'};
                    page-break-inside: avoid;
                    margin: 0;
                    padding: 0;
                ">
                    <img src="${dataUrl}" style="max-width: 54mm; max-height: 27mm;" />
                </div>
            `;
        }).join('');

        printWindow.document.write(`
            <!DOCTYPE html>
            <html>
                <head>
                    <title>Barcode Print</title>
                    <style>
                        @page {
                            size: 57mm 30mm;
                            margin: 0;
                        }
                        body {
                            margin: 0;
                            padding: 0;
                        }
                        .barcode-page {
                            background: white;
                        }
                    </style>
                </head>
                <body>
                    ${barcodesHTML}
                </body>
            </html>
        `);

        printWindow.document.close();

        // Wait for images to load then print
        setTimeout(() => {
            printWindow.print();
            printWindow.close();
        }, 250);
    };

    return (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-card border border-border rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
                {/* Header */}
                <div className="flex items-center justify-between p-6 border-b border-border no-print">
                    <div>
                        <h2 className="text-2xl font-bold">Barcode Chop Etish</h2>
                        <p className="text-sm text-muted-foreground mt-1">Xprinter XP-635B uchun optimallashtirilgan</p>
                    </div>
                    <button
                        onClick={onClose}
                        className="p-2 hover:bg-muted rounded-lg transition-colors"
                    >
                        <X className="w-5 h-5" />
                    </button>
                </div>

                {/* Barcodes Preview */}
                <div className="p-6 space-y-4 no-print">
                    <div className="bg-blue-500/10 border border-blue-500/20 rounded-lg p-4">
                        <p className="text-sm text-blue-600 dark:text-blue-400">
                            <strong>Printer:</strong> Xprinter XP-635B (Thermal Label Printer)
                        </p>
                        <p className="text-sm text-blue-600 dark:text-blue-400 mt-1">
                            <strong>Label Size:</strong> 57mm x 30mm
                        </p>
                        <p className="text-sm text-blue-600 dark:text-blue-400 mt-1">
                            <strong>Barcodes:</strong> {barcodes.length} ta (har biri alohida qog'ozda)
                        </p>
                    </div>
                    {barcodes.map((barcode, index) => (
                        <div key={index} className="flex flex-col items-center justify-center p-4 border border-border rounded-lg bg-white">
                            <canvas
                                ref={(el) => { previewCanvasRefs.current[index] = el; }}
                                className="barcode-canvas"
                            />
                            <p className="text-xs text-muted-foreground mt-2 font-mono">{barcode}</p>
                        </div>
                    ))}
                </div>

                {/* Print-only Barcodes - Each as separate page */}
                {barcodes.map((barcode, index) => (
                    <div key={`print-${index}`} className="barcode-print-page">
                        <canvas
                            ref={(el) => { printCanvasRefs.current[index] = el; }}
                            className="barcode-print-canvas"
                        />
                    </div>
                ))}

                {/* Actions */}
                <div className="flex items-center justify-end gap-4 p-6 border-t border-border no-print">
                    <button
                        onClick={onClose}
                        className="px-6 py-2.5 rounded-lg hover:bg-muted transition-colors font-medium"
                    >
                        Yopish
                    </button>
                    <button
                        onClick={handlePrint}
                        className="flex items-center gap-2 px-6 py-2.5 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-all shadow-lg hover:shadow-xl font-medium"
                    >
                        <Printer className="w-5 h-5" />
                        Chop Etish
                    </button>
                </div>
            </div>

            {/* Print Styles - Optimized for Xprinter XP-635B (57mm x 30mm) */}
            <style jsx global>{`
    @media print {
        @page {
            size: 57mm 30mm;
            margin: 0;
        }

        html, body {
            margin: 0;
            padding: 0;
            width: 57mm;
            height: 30mm;
        }

        /* Hide everything except print pages */
        body * {
            visibility: hidden;
        }

            /* Show print pages and their children */
            .barcode-print-page,
            .barcode-print-page * {
                visibility: visible!important;
            }

            /* Each barcode fills exactly one page */
            .barcode-print-page {
                position: relative;
                width: 57mm!important;
                height: 30mm!important;
                min-height: 30mm!important;
                max-height: 30mm!important;
                margin: 0;
                padding: 0;
                background: white;
                display: flex!important;
                align-items: center;
                justify-content: center;
                overflow: hidden;
                page-break-before: always;
                page-break-after: always;
                page-break-inside: avoid;
            }
            
            .barcode-print-page:first-child {
                page-break-before: auto;
            }
            
            .barcode-print-page:last-child {
                page-break-after: auto;
            }
            
            .barcode-print-canvas {
                display: block;
                max-width: 54mm;
                max-height: 27mm;
            }

            /* Hide UI elements */
            .no-print {
                display: none!important;
            }
    }
    `}</style>
        </div>
    );
}
