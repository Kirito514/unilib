/**
 * Format name from UPPERCASE to Title Case
 * Example: "FAYZULLAYEV ORZUBEK KAMALIDDIN O'G'LI" → "Fayzullayev Orzubek Kamaliddin O'g'li"
 */
export function formatName(name: string): string {
    if (!name) return '';

    return name
        .toLowerCase()
        .split(' ')
        .map(word => {
            if (!word) return '';
            // Capitalize first letter, keep rest lowercase
            return word.charAt(0).toUpperCase() + word.slice(1);
        })
        .join(' ');
}

/**
 * Generate QR code data URL from student ID
 */
export async function generateQRCode(studentId: string): Promise<string> {
    try {
        const QRCode = (await import('qrcode')).default;
        return await QRCode.toDataURL(studentId, {
            width: 300,
            margin: 2,
            color: {
                dark: '#000000',
                light: '#FFFFFF',
            },
        });
    } catch (error) {
        console.error('QR code generation error:', error);
        return '';
    }
}

/**
 * Generate barcode data URL from student ID
 */
export async function generateBarcode(studentId: string): Promise<string> {
    try {
        const JsBarcode = (await import('jsbarcode')).default;
        const canvas = document.createElement('canvas');
        JsBarcode(canvas, studentId, {
            format: 'CODE128',
            width: 2,
            height: 80,
            displayValue: true,
        });
        return canvas.toDataURL();
    } catch (error) {
        console.error('Barcode generation error:', error);
        return '';
    }
}
