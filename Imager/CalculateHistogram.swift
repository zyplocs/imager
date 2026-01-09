import CoreImage

actor HistogramCalculator {
    enum HistogramError: Error {
        case couldNotMakeFilter
        case noOutputImage
        case renderingFailed
    }
    
    // Cache the context to avoid recreating it
    private let context = CIContext()
    
    /// Asynchronously calculate the luminance histogram
    func compute(from inputImage: CIImage, bins: Int = 256) throws -> [Float] {
        // Convert to Grayscale
        /// Use a matrix to map *RGB* to standard Rec.709 luminance
        let luma = inputImage.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0),
            "inputGVector": CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0),
            "inputBVector": CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0),
            "inputAVector": CIVector(x: 0,      y: 0,      z: 0,      w: 1),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
        ])
        
        // Set-up Histogram Filter
        let extent = luma.extent.integral
        let pixelCount = Float(extent.width * extent.height)
        // Use raw counts from the filter; we'll normalize after reading
        let scale: Float = 1.0
        
        guard let filter = CIFilter(name: "CIAreaHistogram") else {
            throw HistogramError.couldNotMakeFilter
        }
        filter.setValue(luma, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: "inputExtent")
        filter.setValue(bins, forKey: "inputCount")
        filter.setValue(scale, forKey: "inputScale")
        
        guard let histImage = filter.outputImage else {
            throw HistogramError.noOutputImage
        }
        
        // Render to CGImage...a 256×1 image
        let bounds = CGRect(x: 0, y: 0, width: bins, height: 1)
        
        // Force Float32 output
        guard let cgImage = context.createCGImage(
            histImage,
            from: bounds,
            format: .RGBAf,
            colorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!
        ) else {
            throw HistogramError.renderingFailed
        }
        
        // Read Pixel Data
        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else {
            throw HistogramError.renderingFailed
        }
        
        // Extract Red Channel
        var result: [Float] = [Float](repeating: 0, count: bins)
        
        let floatPtr = ptr.withMemoryRebound(to: Float.self, capacity: bins * 4) { $0 }

        for i in 0..<bins {
            result[i] = floatPtr[i * 4]
        }
        
//        // Normalize counts so that the histogram sums to 1.0
//        if pixelCount > 0 {
//            for i in 0..<bins {
//                result[i] /= pixelCount
//            }
//        }
        
        #if DEBUG
        let dataLength = CFDataGetLength(data)
        print("[HistogramCalculator] extent: \(extent) pixelCount: \(Int(pixelCount)) scale: \(scale)")
        print("[HistogramCalculator] histImage extent: \(histImage.extent) cgImage: \(cgImage.width)x\(cgImage.height) bpc: \(cgImage.bitsPerComponent) bpr: \(cgImage.bytesPerRow) dataLength: \(dataLength)")
        let sum = result.reduce(0, +)
        let minVal = result.min() ?? 0
        let maxVal = result.max() ?? 0
        let maxIndex = result.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        let previewCount = min(16, result.count)
        let preview = result.prefix(previewCount)
        print("[HistogramCalculator] sum: \(sum), min: \(minVal), max: \(maxVal) @ index \(maxIndex)")
        print("[HistogramCalculator] first \(previewCount) bins: \(Array(preview))")
        #endif
        
        return result
    }
}

