import SwiftUI

// MARK: - StoryChoice Struct
struct StoryChoice: Identifiable {
    let id = UUID()
    let title: String
    var description: String
    let icon: String
    let nextSceneId: String
}

// MARK: - StoryScene Struct
struct StoryScene {
    let id: String
    let title: String
    var description: String
    let evidencePercentage: Int
    let choices: [StoryChoice]
    let isEnding: Bool
}

// MARK: - StoryManager Class
class StoryManager: ObservableObject {
    static let shared = StoryManager()

    @Published var currentSceneId = "arrival"
    @Published var evidenceCollected = 0
    @Published var isLoadingDescription = false

    var currentScene: StoryScene {
        scenes[currentSceneId] ?? initialScene
    }

    private let initialScene = StoryScene(
        id: "arrival",
        title: "The Vanished Mogul",
        description: "A wealthy businessman has vanished under suspicious circumstances in this foggy small town. The mansion looms before you, its secrets waiting to be uncovered...",
        evidencePercentage: 0,
        choices: [
            StoryChoice(
                title: "Interview the Family",
                description: "Question the family members gathered in the parlor",
                icon: "person.2.fill",
                nextSceneId: "family_parlor"
            ),
            StoryChoice(
                title: "Search the Study",
                description: "Investigate the businessman's private office",
                icon: "magnifyingglass.circle.fill",
                nextSceneId: "office_study"
            )
        ],
        isEnding: false
    )

    @Published private var scenes: [String: StoryScene] = [:]

    private init() {
        setupScenes()
    }

    private func setupScenes() {
        scenes["arrival"] = initialScene
        
        // 2A. Family Parlor Branch
        scenes["family_parlor"] = StoryScene(
            id: "family_parlor",
            title: "Family Secrets",
            description: "The wife is tearful, but the son avoids eye contact. The tension in the room is palpable.",
            evidencePercentage: 20,
            choices: [
                StoryChoice(
                    title: "Confront the Son",
                    description: "Directly question his suspicious behavior",
                    icon: "person.fill.questionmark",
                    nextSceneId: "confront_son"
                ),
                StoryChoice(
                    title: "Reassure the Wife",
                    description: "Build trust through empathy",
                    icon: "heart.fill",
                    nextSceneId: "reassure_wife"
                )
            ],
            isEnding: false
        )
        
        // 2B. Office Study Branch
        scenes["office_study"] = StoryScene(
            id: "office_study",
            title: "Office Clues",
            description: "You find a torn note mentioning a meeting at the docks. Time is of the essence.",
            evidencePercentage: 20,
            choices: [
                StoryChoice(
                    title: "Decode the Note",
                    description: "Piece together the torn fragments",
                    icon: "doc.text.magnifyingglass",
                    nextSceneId: "decode_note"
                ),
                StoryChoice(
                    title: "Search Further",
                    description: "Look for more clues in the study",
                    icon: "folder.fill.badge.plus",
                    nextSceneId: "hidden_drawer"
                )
            ],
            isEnding: false
        )
        
        // 3A. Son's Slip-Up
        scenes["confront_son"] = StoryScene(
            id: "confront_son",
            title: "Son's Confession",
            description: "The son admits his father owed dangerous people money. The plot thickens.",
            evidencePercentage: 40,
            choices: [
                StoryChoice(
                    title: "Visit Loan Shark",
                    description: "Track down the local loan shark",
                    icon: "dollarsign.circle.fill",
                    nextSceneId: "loan_shark"
                ),
                StoryChoice(
                    title: "Check Records",
                    description: "Investigate financial records",
                    icon: "doc.text.fill",
                    nextSceneId: "financial_records"
                )
            ],
            isEnding: false
        )
        
        // 3B. Wife's Confession
        scenes["reassure_wife"] = StoryScene(
            id: "reassure_wife",
            title: "Wife's Revelation",
            description: "The wife reveals her husband had an affair. New leads emerge.",
            evidencePercentage: 40,
            choices: [
                StoryChoice(
                    title: "Find Mistress",
                    description: "Track down the mistress",
                    icon: "person.fill.questionmark",
                    nextSceneId: "mistress_investigation"
                ),
                StoryChoice(
                    title: "Search House",
                    description: "Look for evidence of the affair",
                    icon: "house.fill",
                    nextSceneId: "house_search"
                )
            ],
            isEnding: false
        )
        
        // 3C. Decoding the Note
        scenes["decode_note"] = StoryScene(
            id: "decode_note",
            title: "Hidden Message",
            description: "The note reveals a late-night meeting at the docks. Time is crucial.",
            evidencePercentage: 40,
            choices: [
                StoryChoice(
                    title: "Stake Out",
                    description: "Watch the docks at midnight",
                    icon: "eye.fill",
                    nextSceneId: "dock_stakeout"
                ),
                StoryChoice(
                    title: "Alert Police",
                    description: "Inform local authorities",
                    icon: "bell.fill",
                    nextSceneId: "police_involvement"
                )
            ],
            isEnding: false
        )
        
        // 3D. Hidden Drawer
        scenes["hidden_drawer"] = StoryScene(
            id: "hidden_drawer",
            title: "Locked Secret",
            description: "You find a locked drawer that might contain crucial evidence.",
            evidencePercentage: 40,
            choices: [
                StoryChoice(
                    title: "Force It",
                    description: "Break open the drawer",
                    icon: "hammer.fill",
                    nextSceneId: "forced_drawer"
                ),
                StoryChoice(
                    title: "Find Key",
                    description: "Search for the key",
                    icon: "key.fill",
                    nextSceneId: "search_key"
                )
            ],
            isEnding: false
        )
        
        // 4A. Loan Shark Confrontation
        scenes["loan_shark"] = StoryScene(
            id: "loan_shark",
            title: "Dangerous Deal",
            description: "The loan shark demands payment for information. Choose carefully.",
            evidencePercentage: 60,
            choices: [
                StoryChoice(
                    title: "Make Deal",
                    description: "Pay for information",
                    icon: "banknote.fill",
                    nextSceneId: "ending_scheme"
                ),
                StoryChoice(
                    title: "Threaten",
                    description: "Force the truth out",
                    icon: "exclamationmark.triangle.fill",
                    nextSceneId: "ending_justice"
                )
            ],
            isEnding: false
        )
        
        // Endings
        scenes["ending_justice"] = StoryScene(
            id: "ending_justice",
            title: "Justice Served",
            description: "You rescue the businessman, but it's revealed he was hiding his crimes. The town is left divided, but justice prevails.",
            evidencePercentage: 100,
            choices: [],
            isEnding: true
        )
        
        scenes["ending_confession"] = StoryScene(
            id: "ending_confession",
            title: "Family's Fall",
            description: "The wife admits she staged the disappearance to protect their empire. The family's downfall shakes the town, and their legacy crumbles.",
            evidencePercentage: 100,
            choices: [],
            isEnding: true
        )
    }

    // MARK: - Story Management Functions

    func moveToScene(_ sceneId: String) {
        withAnimation {
            currentSceneId = sceneId
            if let scene = scenes[sceneId] {
                evidenceCollected = scene.evidencePercentage
            }
        }
    }

    func resetStory() {
        currentSceneId = "arrival"
        evidenceCollected = 0
    }

    func updateCurrentSceneDescription(for sceneId: String, with newDescription: String) {
        if var scene = scenes[sceneId] {
            scene.description = newDescription
            scenes[sceneId] = scene
        }
    }

    func fetchNewDescription(for genre: String) {
        isLoadingDescription = true

        // Iterate over all scenes to update their descriptions
        for (sceneId, scene) in scenes {
            let currentStoryPart = scene.description
            let systemMessage = "Modify this investigation story with this genre \(genre): \(currentStoryPart)"
            
            let url = URL(string: "https://b3de-2601-8c-4a7e-3cd0-340f-2fbc-361c-5ab9.ngrok-free.app/gpt")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = ["input": systemMessage]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isLoadingDescription = false
                    }
                    return
                }
                guard let data = data else { return }
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let generatedStoryPart = json["response"] as? String {
                    DispatchQueue.main.async {
                        self.updateCurrentSceneDescription(for: sceneId, with: generatedStoryPart)
                        self.isLoadingDescription = false
                    }
                }
            }.resume()
        }
    }
}
