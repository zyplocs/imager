//
//  ContentView.swift
//  Imager
//
//  Created by Eli J on 1/2/26.
//

import SwiftUI
import PhotosUI
import CoreImage

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var histogramData: [Float] = []
    @State private var isCalculating: Bool = false
    @State private var errorMessage: String?
    
    @State private var calculator = HistogramCalculator()
    
    var body: some View {
        NavigationStack{
            VStack {
                // Image Viewer
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .padding()
                        .shadow(radius: 5)
                } else {
                    ContentUnavailableView(
                        "No Image Selected",
                        systemImage: "photo.badge.plus",
                        description: Text("Tap the photo icon to analyze an image.")
                    )
                }
                
                // Histogram
                if isCalculating {
                    ProgressView("Analyzing Luminance…")
                        .padding()
                } else if !histogramData.isEmpty {
                    Text("Luminance Distribution")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.top)
                    
                    HistogramChartView(bins: histogramData)
                        .padding()
                        .transition(.blurReplace)
                } else if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Imager")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Image(systemName: "photo.on.rectangle")
                            .imageScale(.large)
                    }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                
                Task {
                    isCalculating = true
                    errorMessage = nil
                    
                    do {
                        if let data = try await newItem.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data),
                           let ciImage = CIImage(image: uiImage) {
                            
                            self.selectedImage = uiImage
                            
                            // Orientation
                            let orientation = uiImage.imageOrientation.exifOrientation
                            let orientedImage = ciImage.oriented(forExifOrientation: orientation)
                            // Perform the calculation in background as a detached task
                            let histogram = try await calculator.compute(from: orientedImage)
                            
                            withAnimation {
                                self.histogramData = histogram
                            }

                            // Print statement to assist console debugging
//                            print("count:", histogramData.count,
//                                  "sum:", histogramData.reduce(0,+),
//                                  "max:", histogramData.max() ?? -1)
                        }
                    } catch {
                        self.errorMessage = "Failed to process image: \(error.localizedDescription)"
                    }
                    
                    isCalculating = false
                }
            }
        }
    }
}


extension UIImage.Orientation {
    /// Matches CGImagePropertyOrientation / EXIF orientation codes.
    var exifOrientation: Int32 {
        switch self {
        case .up: return 1
        case .upMirrored: return 2
        case .down: return 3
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .right: return 6
        case .rightMirrored: return 7
        case .left: return 8
        @unknown default: return 1
        }
    }
}

#Preview {
    ContentView()
}
