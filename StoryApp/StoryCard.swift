import SwiftUI

// MARK: - StoryCard View
/// A SwiftUI View that represents a card displaying a story scene.
/// The card includes the case file number, title, and description of the scene.
struct StoryCard: View {
    let scene: StoryScene   // The scene that the card represents
    
    var body: some View {
        VStack(spacing: 25) {
            
            // MARK: - Case File Header
            /// Displays the case file number and an icon.
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.red.opacity(0.8))
                Text("CASE FILE #2187")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.red.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.red.opacity(0.3), lineWidth: 1)
                    .background(.ultraThinMaterial)
            )
            
            // MARK: - Title Section
            /// Displays the title of the scene with a detective-themed design.
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.title)
                    .foregroundStyle(.primary.opacity(0.8))
                Text(scene.title)
                    .font(.system(.title, design: .serif))
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            
            // MARK: - Story Content Section
            /// Displays the description of the scene.
            Text(scene.description)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.gray.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .padding()
    }
}
