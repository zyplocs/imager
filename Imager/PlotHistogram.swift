import SwiftUI
import Charts

struct HistogramBin: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
}

struct HistogramChartView: View {
    let bins: [Float]

    var chartData: [HistogramBin] {
        bins.enumerated().map { i, v in
            HistogramBin(index: i, value: Double(v))
        }
    }

    var body: some View {
        Chart(chartData) { b in
            BarMark(
                x: .value("Bin", b.index),
                y: .value("Probability", b.value)
            )
        }
        .frame(height: 220)
        .padding()
    }
}


#Preview {
    HistogramChartView(bins: [512])
}
