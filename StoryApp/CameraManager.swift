import SwiftUI
import AVFoundation

// MARK: - CameraManager Class
/// The CameraManager class handles camera setup, video recording in segments,
/// and uploading video segments for face detection. It is an ObservableObject so that
/// the UI can update based on changes such as recording status or detection results.
class CameraManager: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    
    // MARK: - Published Properties
    @Published var isRecording = false               // Indicates if the camera is currently recording
    @Published var detectionResults: String = ""       // Stores textual face detection results
    @Published var detectedFaces: [Face] = []          // Array of detected Face objects
    @Published var videoMetadata: VideoMetadata?       // Metadata related to the recorded video
    @Published var showFaceDetails: Bool = false       // Flag to trigger display of face details in the UI
    @Published var dominantEmotions: [String] = []     // Stores the dominant emotion for each video segment
    
    // MARK: - Private Properties
    private var captureSession: AVCaptureSession?                // The capture session manages input and output devices
    private var videoOutput: AVCaptureMovieFileOutput?           // Handles the recording of video files
    private var _previewLayer: AVCaptureVideoPreviewLayer?       // Layer to display the live camera feed
    private var currentJobId: String?                            // Optional identifier for tracking uploads (if needed)
    var currentRecordingPath: URL?                               // File URL for the current video segment being recorded
    
    private var recordingTimer: Timer?                           // Timer to manage the recording duration per segment
    private var currentSegment: Int = 0                          // Counter to track the current video segment number
    private var activeUploads: Set<String> = []                  // Set to keep track of active upload job IDs
    
    // Computed property that provides the camera preview layer to the UI
    var previewLayer: AVCaptureVideoPreviewLayer? {
        return _previewLayer
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupCamera()  // Configure the camera inputs and outputs
        startSession() // Start the capture session in the background
    }
    
    // MARK: - Camera Setup Methods
    /// Configures the capture session, adding the video input from the front camera
    /// and setting up the video output for recording.
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        // Attempt to get the default front camera device and create an input object.
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("Error setting up camera input.")
            return
        }
        
        // Add the video input to the capture session if possible.
        if captureSession?.canAddInput(videoInput) == true {
            captureSession?.addInput(videoInput)
        } else {
            print("Could not add video input.")
        }
        
        // Configure the video output for recording movie files.
        videoOutput = AVCaptureMovieFileOutput()
        if let videoOutput = videoOutput, captureSession?.canAddOutput(videoOutput) == true {
            captureSession?.addOutput(videoOutput)
        } else {
            print("Could not add video output.")
        }
        
        // Create and configure the preview layer to show the live camera feed.
        if let captureSession = captureSession {
            _previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            _previewLayer?.videoGravity = .resizeAspectFill
        }
    }
    
    /// Starts the capture session asynchronously on a background thread.
    private func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
            print("Camera session started.")
        }
    }
    
    /// Generates a unique file URL using the current timestamp.
    /// - Returns: A URL pointing to a file in the documents directory.
    private func getUniqueVideoPath() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        return documentsPath.appendingPathComponent("recording-\(timestamp).mp4")
    }
    
    // MARK: - Recording Control Methods
    /// Starts recording by initiating a new video segment.
    func startRecording() {
        startNewSegment()
    }
    
    /// Starts a new video segment recording.
    /// This method sets a timer so that the recording stops after a predefined interval.
    private func startNewSegment() {
        // Create a unique output path for the new video segment.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let outputPath = FileManager.default.temporaryDirectory.appendingPathComponent("video_segment_\(currentSegment)_\(timestamp).mov")
        currentRecordingPath = outputPath
        
        // Start recording to the output path.
        videoOutput?.startRecording(to: outputPath, recordingDelegate: self)
        isRecording = true
        
        // Schedule a timer to stop recording after 5 seconds.
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.handleSegmentComplete()
        }
    }
    
    /// Handles the completion of a video segment.
    /// Stops recording, validates the segment, uploads it, and initiates the next segment.
    private func handleSegmentComplete() {
        // Ensure that a recording is currently active.
        guard isRecording else { return }
        
        // Stop the current recording.
        videoOutput?.stopRecording()
        isRecording = false
        
        // Allow a brief delay to ensure the file is properly written.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // Validate that the recorded file exists and is not empty.
            if let videoPath = self.currentRecordingPath,
               let fileAttributes = try? FileManager.default.attributesOfItem(atPath: videoPath.path),
               let fileSize = fileAttributes[.size] as? NSNumber,
               fileSize.intValue > 0 {
                
                print("Segment \(self.currentSegment) recorded successfully, size: \(fileSize.intValue) bytes")
                self.uploadCurrentSegment()
                
                // Increment the segment counter and start a new recording segment.
                self.currentSegment += 1
                self.startNewSegment()
            } else {
                print("Error: Segment \(self.currentSegment) file is invalid or empty")
                self.currentSegment += 1
                self.startNewSegment()
            }
        }
    }
    
    /// Uploads the current video segment for processing (e.g., face detection).
    private func uploadCurrentSegment() {
        guard let videoPath = currentRecordingPath else { return }
        print("Uploading segment \(currentSegment) from path: \(videoPath)")
        
        // Create a copy of the segment file with a unique name.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let segmentCopyPath = FileManager.default.temporaryDirectory.appendingPathComponent("segment_\(currentSegment)_\(timestamp).mov")
        
        do {
            try FileManager.default.copyItem(at: videoPath, to: segmentCopyPath)
            
            // Upload the copied video file.
            uploadVideo(fileURL: segmentCopyPath) { [weak self] result in
                switch result {
                case .success(let response):
                    // Process the upload response to extract face detection information.
                    self?.processSegmentResponse(response)
                    // Clean up by removing the temporary copy.
                    try? FileManager.default.removeItem(at: segmentCopyPath)
                case .failure(let error):
                    print("Segment \(self?.currentSegment ?? 0) upload error: \(error)")
                }
            }
        } catch {
            print("Error copying segment file: \(error)")
        }
    }
    
    // MARK: - Response Processing Methods
    /// Processes the response from a video segment upload by determining the dominant emotion.
    /// - Parameter response: The face detection response from the server.
    private func processSegmentResponse(_ response: FaceDetectionResponse) {
        // Map over the faces to extract the most confident emotion from each.
        let allEmotions = response.faces.compactMap { faceWrapper -> String? in
            let emotions = faceWrapper.face.emotions
            return emotions.max(by: { $0.confidence < $1.confidence })?.type
        }
        
        // Determine the most frequently occurring emotion.
        let dominantEmotion = findMostFrequent(emotions: allEmotions)
        DispatchQueue.main.async {
            self.dominantEmotions.append(dominantEmotion ?? "UNKNOWN")
        }
    }
    
    /// Determines the most frequent emotion from an array of emotion strings.
    /// - Parameter emotions: Array containing emotion strings.
    /// - Returns: The most frequent emotion or nil if the array is empty.
    private func findMostFrequent(emotions: [String]) -> String? {
        let counts = emotions.reduce(into: [:]) { counts, emotion in
            counts[emotion, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    // MARK: - Recording Termination Methods
    /// Stops recording, finalizes any current segment, and cleans up the camera session.
    func stopRecording() {
        // If a recording is active, stop it.
        if isRecording {
            videoOutput?.stopRecording()
            isRecording = false
        }
        
        // Invalidate any active recording timer.
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Stop the camera capture session.
        captureSession?.stopRunning()
        
        // Remove and clear the preview layer from the view.
        _previewLayer?.removeFromSuperlayer()
        _previewLayer = nil
        
        // Upload the last segment if it exists.
        if let _ = currentRecordingPath {
            uploadCurrentSegment()
        }
        
        // Reset the segment counter for future recordings.
        currentSegment = 0
        
        print("Camera session and recording stopped")
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate Methods
    /// Delegate method called when the recording for a file output finishes.
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // Handle any errors encountered during recording.
        if let error = error {
            print("Recording error: \(error.localizedDescription)")
            return
        }
        
        print("Recording finished successfully at: \(outputFileURL)")
        
        // Check the size of the recorded file and log it.
        if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: outputFileURL.path),
           let fileSize = fileAttributes[.size] as? NSNumber {
            print("Recorded video file size: \(fileSize.intValue) bytes")
        } else {
            print("Could not retrieve file size.")
        }
    }
    
    // MARK: - Face Detection Response Handling
    /// Updates the UI-bound properties with the results from the face detection response.
    /// - Parameter response: The response object containing face detection details.
    private func handleFaceDetectionResponse(_ response: FaceDetectionResponse) {
        DispatchQueue.main.async {
            self.detectionResults = "Detected \(response.faces.count) faces."
            self.detectedFaces = response.faces.map { $0.face }
            self.videoMetadata = response.videoMetadata
            self.showFaceDetails = true
            
            if response.faces.isEmpty {
                print("No faces detected.")
            } else {
                print("Detected \(response.faces.count) faces.")
            }
            print("Results received, navigating to FaceResultsView")
        }
    }
    
    // MARK: - Video Upload Methods
    /// Uploads the specified video file to a remote server for face detection.
    /// - Parameters:
    ///   - fileURL: The URL of the video file to be uploaded.
    ///   - completion: Completion handler returning either a FaceDetectionResponse on success or an error.
    func uploadVideo(fileURL: URL, completion: @escaping (Result<FaceDetectionResponse, Error>) -> Void) {
        // Generate a unique identifier for this upload and track it.
        let uploadId = UUID().uuidString
        activeUploads.insert(uploadId)
        
        // Define the server endpoint URL.
        let url = URL(string: "https://b3de-2601-8c-4a7e-3cd0-340f-2fbc-361c-5ab9.ngrok-free.app/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create a unique boundary for multipart/form-data.
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build the body data for the upload request.
        var body = Data()
        let filename = fileURL.lastPathComponent
        let mimeType = "video/mp4" // MIME type for the video file
        
        // Append the initial multipart boundary and header information.
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        
        // Append the video file data.
        do {
            let videoData = try Data(contentsOf: fileURL)
            body.append(videoData)
        } catch {
            print("Error reading video file: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        // Append the closing multipart boundary.
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Create and start the upload task.
        let task = URLSession.shared.uploadTask(with: request, from: body) { [weak self] data, response, error in
            // Ensure that the upload ID is removed once the task completes.
            defer {
                self?.activeUploads.remove(uploadId)
            }
            
            // Handle any error from the upload.
            if let error = error {
                print("Upload \(uploadId) error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // Validate that a proper HTTP response was received.
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response received.")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "Invalid response", code: -1, userInfo: nil)))
                }
                return
            }
            
            print("HTTP Response Status Code: \(httpResponse.statusCode)")
            
            // Ensure the response status code indicates success.
            guard (200...299).contains(httpResponse.statusCode) else {
                print("Server error: \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "Server error", code: httpResponse.statusCode, userInfo: nil)))
                }
                return
            }
            
            // Validate that data was received.
            guard let data = data else {
                print("No data received from upload response.")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                }
                return
            }
            
            // Optional: Debug print the raw response as a string.
            if let responseString = String(data: data, encoding: .utf8) {
                // Decode and print summary information if available.
                if let response = try? JSONDecoder().decode(FaceDetectionResponse.self, from: data) {
                    let facesCount = response.faces.count
                    let duration = response.videoMetadata?.durationMillis ?? 0
                    let mainEmotion = response.faces.first?.face.emotions.max(by: { $0.confidence < $1.confidence })?.type ?? "unknown"
                    print("✅ Upload \(uploadId) complete - Faces: \(facesCount), Duration: \(duration)ms, Main emotion: \(mainEmotion)")
                }
            }
            
            // Parse the upload response to get the face detection results.
            do {
                let faceDetectionResponse = try JSONDecoder().decode(FaceDetectionResponse.self, from: data)
                DispatchQueue.main.async { [weak self] in
                    self?.handleFaceDetectionResponse(faceDetectionResponse)
                    completion(.success(faceDetectionResponse))
                }
            } catch {
                print("Error parsing upload response: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
}
