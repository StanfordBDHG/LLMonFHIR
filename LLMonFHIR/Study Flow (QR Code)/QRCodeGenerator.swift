//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import SwiftUI


enum QRCodeGenerator {
    enum CorrectionLevel: String {
        case low = "L"
        case medium = "M"
        case high = "Q"
        case highest = "H"
    }
    
    static func qrCode(withPayload payload: String, correctionLevel: CorrectionLevel) -> Image? {
        guard let payload = payload.data(using: .utf8) else {
            return nil
        }
        let qrCodeGenerator = CIFilter.qrCodeGenerator()
        qrCodeGenerator.message = payload
        qrCodeGenerator.correctionLevel = correctionLevel.rawValue
        guard var ciImage = qrCodeGenerator.outputImage else {
            return nil
        }
        // for some reason simply turning the CIImage into a UIImage and turning that into a SwiftUI.Image doesn't work
        // (the image has a size but doesn't render anything);
        // instead we do CIImage -> CGImage -> UIImage -> SwiftUI.Image
        let context = CIContext()
        ciImage = ciImage.transformed(by: .identity.scaledBy(x: 100, y: 100)) // the QR code image has 1 pixel per square by default
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return Image(uiImage: UIImage(cgImage: cgImage))
    }
}
