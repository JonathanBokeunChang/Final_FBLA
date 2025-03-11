import SwiftUI

// MARK: - ChoicesView
/// The ChoicesView displays a list of story choices for the user to select from.
/// It updates the UI based on the user's selection and triggers actions accordingly.
struct ChoicesView: View {
    
    // MARK: - Properties
    let choices: [StoryChoice]  // The available choices in the story
    let onChoiceSelected: (String) -> Void  // Action to trigger when a choice is selected
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            // Title text
            Text("Your Next Move, Detective")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.yellow)
                .padding(.bottom, 10)
            
            // Display each choice button
            ForEach(choices) { choice in
                DetectiveChoiceButton(
                    choice: choice.title,
                    description: choice.description,
                    icon: choice.icon,
                    accentColor: .red.opacity(0.8),
                    action: {
                        // Perform the action with an animation when a choice is selected
                        withAnimation(.easeInOut(duration: 0.3)) {
                            onChoiceSelected(choice.nextSceneId)
                        }
                    }
                )
            }
        }
        .padding()
    }
}

// MARK: - DetectiveChoiceButton
/// The DetectiveChoiceButton displays a button for each choice with an icon, title, description, and action.
/// It includes a visual style with a rounded background and shadow effects.
struct DetectiveChoiceButton: View {
    
    // MARK: - Properties
    let choice: String  // The title of the choice
    var description: String  // Description of the choice
    let icon: String  // The icon representing the choice
    let accentColor: Color  // Accent color for the button
    let action: () -> Void  // Action to execute when the button is tapped
    
    // MARK: - Body
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                // Icon with custom styling
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)
                        .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(accentColor)
                }
                
                // Choice text
                VStack(alignment: .leading, spacing: 4) {
                    Text(choice)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Chevron icon indicating navigation
                Image(systemName: "chevron.right")
                    .foregroundStyle(accentColor.opacity(0.8))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(accentColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
