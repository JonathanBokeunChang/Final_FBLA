import SwiftUI
import PDFKit

// MARK: - ReportView
/// The ReportView allows users to customize and generate a report based on face detection results,
/// video metadata, and story details. It also includes functionality to create and save a PDF.
struct ReportView: View {
    
    // MARK: - Properties
    @State private var includeFaces: Bool = true          // Toggle to include faces information
    @State private var includeEmotions: Bool = true       // Toggle to include emotions data
    @State private var includeMetadata: Bool = true       // Toggle to include video metadata
    @State private var includeStoryDetails: Bool = true     // Toggle to include story details
    @State private var reportText: String = ""            // Generated report text
    
    let faces: [Face]                                     // Array of detected faces
    let videoMetadata: VideoMetadata?                     // Video metadata (if available)
    let dominantEmotions: [String]                        // Dominant emotions for each segment
    
    @State private var storyTitle: String                 // Title of the story for the report
    @State private var storyDescription: String           // Description of the story for the report
    
    // MARK: - Initialization
    init(faces: [Face], videoMetadata: VideoMetadata?, dominantEmotions: [String], storyTitle: String, storyDescription: String) {
        self.faces = faces
        self.videoMetadata = videoMetadata
        self.dominantEmotions = dominantEmotions
        self._storyTitle = State(initialValue: storyTitle)
        self._storyDescription = State(initialValue: storyDescription)
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            // Form to customize which details to include in the report
            Form {
                Toggle("Include Faces", isOn: $includeFaces)
                Toggle("Include Emotions", isOn: $includeEmotions)
                Toggle("Include Video Metadata", isOn: $includeMetadata)
                Toggle("Include Story Details", isOn: $includeStoryDetails)
                
                // Editable fields for story details when enabled
                if includeStoryDetails {
                    TextField("Story Title", text: $storyTitle)
                    TextField("Story Description", text: $storyDescription)
                }
            }
            
            // Button to trigger report generation
            Button("Generate Report") {
                generateReport()
            }
            .padding()
            
            // Display the generated report text if available
            if !reportText.isEmpty {
                ScrollView {
                    Text(reportText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding()
                }
            }
        }
        .navigationTitle("Customize Report")
    }
    
    // MARK: - Report Generation Methods
    
    /// Gathers selected data and constructs the report text.
    func generateReport() {
        var reportData = [String]()
        
        if includeStoryDetails {
            reportData.append("Story Title: \(storyTitle)")
            reportData.append("Story Description: \(storyDescription)")
        }
        
        if includeFaces {
            reportData.append("Faces Detected: \(faces.count)")
        }
        
        if includeEmotions {
            reportData.append("Dominant Emotions: \(dominantEmotions.joined(separator: ", "))")
        }
        
        if includeMetadata, let metadata = videoMetadata {
            reportData.append("Video Metadata: Codec: \(metadata.codec), Duration: \(metadata.durationMillis) ms, Frame Rate: \(metadata.frameRate) fps, Resolution: \(metadata.frameWidth)x\(metadata.frameHeight)")
        }
        
        // Update the report text displayed to the user.
        reportText = reportData.joined(separator: "\n")
    }
    
    // MARK: - PDF Generation Methods
    
    /// Creates a PDF page with the given text.
    /// - Parameter text: The text to be rendered on the PDF page.
    /// - Returns: An optional PDFPage if creation is successful.
    func createPDFPage(with text: String) -> PDFPage? {
        // Define a standard page size (8.5 x 11 inches)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            text.draw(in: pageRect.insetBy(dx: 20, dy: 20), withAttributes: attributes)
        }
        
        // Create a PDFDocument from the rendered data and return the first page.
        if let document = PDFDocument(data: data) {
            return document.page(at: 0)
        }
        
        return nil
    }
    
    /// Saves the provided PDF document to the app's documents directory.
    /// - Parameter document: The PDFDocument to be saved.
    func savePDF(_ document: PDFDocument) {
        // Locate the documents directory.
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfPath = documentsPath.appendingPathComponent("Report.pdf")
        
        // Attempt to write the PDF to disk.
        if document.write(to: pdfPath) {
            print("PDF saved successfully at \(pdfPath)")
        } else {
            print("Failed to save PDF.")
        }
    }
}
