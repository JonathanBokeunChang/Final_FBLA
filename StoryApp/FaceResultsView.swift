import SwiftUI

// MARK: - FaceResultsView
/// The FaceResultsView displays the outcome of the face detection process.
/// It includes sections for a header, loading indicator, emotional timeline, video metadata,
/// and an option to generate a detailed report.
struct FaceResultsView: View {
    
    // MARK: - Properties
    let faces: [Face]                           // Array of detected faces
    let videoMetadata: VideoMetadata?           // Metadata for the recorded video
    let dominantEmotions: [String]              // List of dominant emotions for each video segment
    
    @State private var isLoading: Bool = true   // Flag to control loading state
    @State private var showReportView: Bool = false // Controls presentation of the report view

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                
                if isLoading {
                    loadingView
                } else {
                    emotionsTimelineView
                    
                    if let metadata = videoMetadata {
                        videoMetadataView(metadata: metadata)
                    }
                    
                    // Button to generate and display a report
                    Button("Generate Report") {
                        showReportView = true
                    }
                    .padding()
                    .sheet(isPresented: $showReportView) {
                        // Calculate the total time based on segment count (each segment is 5 seconds)
                        let lengthPlayed = dominantEmotions.count * 5
                        // Get story info for report details (replace with actual logic if needed)
                        let storyInfo = getStoryInfo(for: "ending_justice")
                        
                        ReportView(
                            faces: faces,
                            videoMetadata: videoMetadata,
                            dominantEmotions: dominantEmotions,
                            storyTitle: storyInfo.title,
                            storyDescription: storyInfo.description
                        )
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Simulate a delay to wait for emotion processing
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false
            }
        }
    }
    
    // MARK: - Private Subviews
    
    /// Header view displaying the title.
    private var headerView: some View {
        Text("Face Detection Results")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding()
    }
    
    /// Loading view with a progress indicator and message.
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            Text("**Please wait for the machine learning model to determine emotions...**")
                .padding(30)
                .background(.white.opacity(0.5))
                .foregroundStyle(.blue)
        }
        .foregroundColor(.blue)
        .background(Color.white.opacity(0.8))
        .cornerRadius(10)
    }
    
    /// View that displays an emotional timeline based on the dominant emotions.
    private var emotionsTimelineView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Emotional Timeline")
                .font(.headline)
                .padding(.bottom, 5)
            
            // List each time segment with its corresponding emotion
            ForEach(dominantEmotions.indices, id: \.self) { index in
                HStack {
                    Text("0:\(index * 5)-0:\((index + 1) * 5)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(dominantEmotions[index])
                        .padding(8)
                        .background(getColorForEmotion(dominantEmotions[index]))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Helper Methods
    
    /// Creates a view to display video metadata.
    /// - Parameter metadata: The VideoMetadata object.
    /// - Returns: A view showing the video's codec, duration, frame rate, and resolution.
    private func videoMetadataView(metadata: VideoMetadata) -> some View {
        VStack(alignment: .leading) {
            Text("Video Metadata")
                .font(.headline)
                .padding(.bottom, 5)
            Text("Codec: \(metadata.codec ?? "N/A")")
            Text("Duration: \(metadata.durationMillis ?? 0) ms")
            Text("Frame Rate: \(metadata.frameRate ?? 0) fps")
            Text("Resolution: \(metadata.frameWidth ?? 0)x\(metadata.frameHeight ?? 0)")
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
    
    /// Returns a color corresponding to the provided emotion.
    /// - Parameter emotion: The emotion string.
    /// - Returns: A Color value representing the emotion.
    private func getColorForEmotion(_ emotion: String) -> Color {
        switch emotion {
        case "HAPPY":
            return Color.green.opacity(0.3)
        case "SAD":
            return Color.blue.opacity(0.3)
        case "ANGRY":
            return Color.red.opacity(0.3)
        case "SURPRISED":
            return Color.yellow.opacity(0.3)
        case "CALM":
            return Color.gray.opacity(0.3)
        case "DISGUSTED":
            return Color.purple.opacity(0.3)
        case "CONFUSED":
            return Color.orange.opacity(0.3)
        case "FEAR":
            return Color.black.opacity(0.3)
        default:
            return Color.white
        }
    }
    
    /// Retrieves story information based on an ending identifier.
    /// - Parameter endingIdentifier: A string identifying the story ending.
    /// - Returns: A tuple containing the story title and description.
    private func getStoryInfo(for endingIdentifier: String) -> (title: String, description: String) {
        let storyEndings = [
            "ending_justice": ("Justice Served", "You rescue the businessman, but it's revealed he was hiding his crimes. The town is left divided, but justice prevails."),
            "ending_confession": ("Family's Fall", "The wife admits she staged the disappearance to protect their empire. The family's downfall shakes the town, and their legacy crumbles."),
            "ending_scheme": ("The Great Escape", "The disappearance was staged to escape debts. You expose the scam, but the businessman vanishes, leaving chaos behind."),
            "ending_discovery": ("Hidden Truth", "The map leads to a hideout with proof of the family's plot. Their exposure brings scandal, but you're offered a major case in the city."),
            // Add more mappings as needed
        ]
        
        return storyEndings[endingIdentifier] ?? ("Unknown Ending", "No description available.")
    }
}
