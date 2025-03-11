//
//  ContentView.swift
//  StoryApp
//
//  Created by Jonathan Chang on 1/19/25.
//

import SwiftUI

// MARK: - ContentView
/// The ContentView serves as the main entry point of the app. It composes the story view with
/// a live camera preview and handles navigation to the face detection results and help screens.
struct ContentView: View {
    
    // MARK: - Properties
    @StateObject private var cameraManager = CameraManager()       // Manages the camera session and recording
    @EnvironmentObject var storyManager: StoryManager               // Provides story-related data and logic
    @State private var showResults = false                          // Controls presentation of the face results view
    @State private var showHelp = false                             // Controls presentation of the help view

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Main Story View with camera manager and story manager environment
                StoryView(cameraManager: cameraManager, showResults: $showResults)
                    .environmentObject(storyManager)
                
                // Overlay camera preview for a small live view
                CameraPreviewView(cameraManager: cameraManager)
                    .frame(width: 200, height: 300)
                    .cornerRadius(10)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()
                    .position(x: UIScreen.main.bounds.width - 120, y: 100)
            }
            // Full screen cover for displaying face detection results
            .fullScreenCover(isPresented: $showResults) {
                FaceResultsView(
                    faces: cameraManager.detectedFaces,
                    videoMetadata: cameraManager.videoMetadata,
                    dominantEmotions: cameraManager.dominantEmotions
                )
            }
            // Toolbar button for help view
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showHelp = true
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            // Sheet presentation for help instructions
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
        }
    }
}

// MARK: - Preview Provider
#Preview {
    ContentView()
}
