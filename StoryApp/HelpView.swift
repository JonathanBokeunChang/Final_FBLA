import SwiftUI

// MARK: - HelpView
/// The HelpView provides users with instructions and guidance on how to use the app.
/// It lists step-by-step directions for navigating the investigation and generating reports.
struct HelpView: View {
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title for the help screen
            Text("Help & Instructions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 20)
            
            // List of step-by-step instructions
            Text("1. Begin your investigation by selecting a story mode.")
            Text("2. Follow the prompts to make decisions and progress through the story.")
            Text("3. Your facial expressions will be recorded to analyze your emotions.")
            Text("4. Generate a report at the end to review your investigation.")
            
            Spacer()
        }
        .padding()
    }
}
