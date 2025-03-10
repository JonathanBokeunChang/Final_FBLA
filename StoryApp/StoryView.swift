import SwiftUI

struct StoryView: View {
    @EnvironmentObject var storyManager: StoryManager
    @Environment(\.dismiss) private var dismiss
    @State private var isTransitioning = false
    @State private var isFinishTransitioning = false
    @State private var showTransition = false
    @State private var showHelp = false
    @ObservedObject var cameraManager: CameraManager
    @Binding var showResults: Bool
    
    var body: some View {
        ZStack {
            // Noir-style background gradient
            LinearGradient(
                colors: [
                    Color(.sRGB, red: 0.1, green: 0.1, blue: 0.2, opacity: 1),
                    Color(.sRGB, red: 0.2, green: 0.2, blue: 0.3, opacity: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Rain effect overlay
            GeometryReader { geometry in
                ForEach(0..<50) { _ in
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 2, height: 10)
                        .offset(x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height))
                }
            }
            
            // Content
            ScrollView {
                VStack(spacing: 30) {
                    // Evidence progress with modified text color
                    ProgressView("Evidence Collected: \(storyManager.evidenceCollected)%")
                        .progressViewStyle(.linear)
                        .tint(.red.opacity(0.8))
                        .foregroundStyle(.yellow)
                        .padding(.horizontal)
                    
                    if storyManager.isLoadingDescription {
                        ProgressView("Generating new story description...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        StoryCard(scene: storyManager.currentScene)
                    }
                    
                    if !storyManager.currentScene.isEnding {
                        ChoicesView(
                            choices: storyManager.currentScene.choices,
                            onChoiceSelected: { nextSceneId in
                                isTransitioning = true
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    storyManager.moveToScene(nextSceneId)
                                }
                            }
                        )
                    } else {
                        Button("Done") {
                            if cameraManager.isRecording {
                                print("Done button pressed - was recording")
                                cameraManager.stopRecording()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    uploadVideo()
                                }
                            } else {
                                print("Done button pressed - not recording")
                                uploadVideo()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red.opacity(0.8))
                        .padding()
                        .sheet(isPresented: $showResults) {
                            FaceResultsView(
                                faces: cameraManager.detectedFaces,
                                videoMetadata: cameraManager.videoMetadata,
                                dominantEmotions: cameraManager.dominantEmotions
                            )
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                cameraManager.startRecording()
                if storyManager.currentSceneId != "arrival" && storyManager.currentSceneId != "default" {
                    storyManager.fetchNewDescription(for: storyManager.currentSceneId)
                }
            }
            .onDisappear {
                cameraManager.stopRecording()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showHelp = true
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
    }

    private func uploadVideo() {
        guard let videoPath = cameraManager.currentRecordingPath else {
            print("No recording path available.")
            return
        }

        print("Attempting to upload video from path: \(videoPath)")
        cameraManager.uploadVideo(fileURL: videoPath) { result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    self.cameraManager.detectedFaces = response.faces.map { $0.face }
                    self.cameraManager.videoMetadata = response.videoMetadata
                    self.showResults = true
                }
            case .failure(let error):
                print("Upload error: \(error.localizedDescription)")
            }
        }
    }
}
