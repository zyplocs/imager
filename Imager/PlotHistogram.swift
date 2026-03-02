import SwiftUI
import Charts

struct HistogramBin: Identifiable {
    let id: UUID = UUID()
    let index: Int
    let value: Double
}

struct HistogramChartView: View {
    let bins: [Float]

    private var chartData: [HistogramBin] {
        bins.enumerated().map { i, v in
            HistogramBin(index: i, value: Double(v) * 100.0)
        }
    }
    
    private var xMax: Int { max(1, bins.count - 1) }
    private var yMax: Double { chartData.map(\.value).max() ?? 0 }

    var body: some View {
        Group {
            if bins.isEmpty {
                ContentUnavailableView(
                    "No histogram yet",
                    systemImage: "chart.bar.axis",
                    description: Text("Pick an image to compute a histogram.")
                )
            } else {
                Chart(chartData) { b in
                    AreaMark(
                        x: .value("Luminance", b.index),
                        y: .value("Frequency", b.value)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.gray.opacity(0.3), .gray.opacity(0.6)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .interpolationMethod(.catmullRom)  // Smooths the curve slightly
                
                    LineMark(
                        x: .value("Luminance", b.index),
                        y: .value("Frequency", b.value)
                    )
                    .foregroundStyle(.gray)
                    .interpolationMethod(.catmullRom)
                }
                .chartXScale(domain: 0...xMax)
                .chartYScale(domain: 0...(max(yMax * 1.05, 0.001)))
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxisLabel("Brightness (0-255)")
                .chartYAxisLabel("Pixels (%)")
            }
        }
        .frame(height: 220)
        .padding()
    }
}
