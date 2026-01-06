//
//  ContentView.swift
//  Imager
//
//  Created by Eli J on 1/2/26.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var histogramData: [Float] = []
    @State private var isCalculating: Bool = false
    @State private var errorMessage: String?
    
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
            .onChange(of: selectedItem) {_, newItem in
                guard let newItem else { return }
                
                Task {
                    isCalculating = true
                    errorMessage = nil
                    
                    do {
                        if let data = try await newItem.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            self.selectedImage = uiImage
                            
                            // Perform Calculation in Background as Detached Task
                            let histogram = try await computeHistogramInBackground(image: uiImage)
                            
                            withAnimation {
                                self.histogramData = histogram
                            }
                        }
                    } catch {
                        self.errorMessage = "Failed to process image: \(error.localizedDescription)"
                    }
                    
                    isCalculating = false
                }
            }
        }
    }
    
    // Helper to bridge the synchronous calculation to an async background context
    private func computeHistogramInBackground(image: UIImage) async throws -> [Float] {
        return try await Task.detached(priority: .userInitiated) {
            return try await luminanceHistogram(from: image)
        }.value
    }
}



#Preview {
    ContentView()
}
