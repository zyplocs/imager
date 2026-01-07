import Testing
import CoreImage
@testable import Imager

struct HistogramCalculatorTests {
    let calculator = HistogramCalculator()

    // Helper: create a solid color CIImage in linear sRGB (approx via RGB initializer)
    private func solidCIImage(gray: CGFloat, size: CGSize = CGSize(width: 64, height: 64)) -> CIImage {
        let color = CIColor(red: gray, green: gray, blue: gray, alpha: 1)
        return CIImage(color: color).cropped(to: CGRect(origin: .zero, size: size))
    }

    // Helper: create a horizontal gradient from black to white
    private func gradientImage(width: Int = 256, height: Int = 1) -> CIImage {
        let start = CIVector(x: 0, y: 0)
        let end = CIVector(x: CGFloat(width), y: 0)
        let grad = CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0": start,
            "inputPoint1": end,
            "inputColor0": CIColor(red: 0, green: 0, blue: 0, alpha: 1),
            "inputColor1": CIColor(red: 1, green: 1, blue: 1, alpha: 1)
        ])!.outputImage!
        return grad.cropped(to: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
    }

    @Test func solidBlack() async throws {
        let img = solidCIImage(gray: 0.0)
        let hist = try await calculator.compute(from: img, bins: 256)

        let sum = hist.reduce(0, +)
        #expect(abs(sum - 1.0) < 1e-3)

        let maxPair = try #require(hist.enumerated().max(by: { $0.element < $1.element }))
        #expect(maxPair.offset == 0)
        #expect(hist[0] > 0.9)
    }

    @Test func solidWhite() async throws {
        let img = solidCIImage(gray: 1.0)
        let hist = try await calculator.compute(from: img, bins: 256)

        let sum = hist.reduce(0, +)
        #expect(abs(sum - 1.0) < 1e-3)

        let maxPair = try #require(hist.enumerated().max(by: { $0.element < $1.element }))
        #expect(maxPair.offset == 255)
        #expect(hist[255] > 0.9)
    }

    @Test func gradient() async throws {
        let img = gradientImage(width: 256, height: 64)
        let hist = try await calculator.compute(from: img, bins: 256)

        let sum = hist.reduce(0, +)
        #expect(abs(sum - 1.0) < 1e-3)

        let minVal = try #require(hist.min())
        let maxVal = try #require(hist.max())
        #expect(maxVal / max(minVal, 1e-6) < 2.5)
    }
}
