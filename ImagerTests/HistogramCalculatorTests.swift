import XCTest
import CoreImage
@testable import Imager // <- replace with your actual module name if different

final class HistogramCalculatorTests: XCTestCase {
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

    func testSolidBlack() async throws {
        let img = solidCIImage(gray: 0.0)
        let hist = try await calculator.compute(from: img, bins: 256)
        let sum = hist.reduce(0, +)
        XCTAssertLessThan(abs(sum - 1.0), 1e-3)
        let maxIndex = hist.enumerated().max(by: { $0.element < $1.element })!.offset
        XCTAssertEqual(maxIndex, 0)
        XCTAssertGreaterThan(hist[0], 0.9)
    }

    func testSolidWhite() async throws {
        let img = solidCIImage(gray: 1.0)
        let hist = try await calculator.compute(from: img, bins: 256)
        let sum = hist.reduce(0, +)
        XCTAssertLessThan(abs(sum - 1.0), 1e-3)
        let maxIndex = hist.enumerated().max(by: { $0.element < $1.element })!.offset
        XCTAssertEqual(maxIndex, 255)
        XCTAssertGreaterThan(hist[255], 0.9)
    }

    func testGradient() async throws {
        let img = gradientImage(width: 256, height: 64)
        let hist = try await calculator.compute(from: img, bins: 256)
        let sum = hist.reduce(0, +)
        XCTAssertLessThan(abs(sum - 1.0), 1e-3)
        let minVal = hist.min() ?? 0
        let maxVal = hist.max() ?? 0
        XCTAssertLessThan(maxVal / max(minVal, 1e-6), 2.5)
    }
}
