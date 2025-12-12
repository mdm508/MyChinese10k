import SwiftUI
import CoreDataModels
import CoreData
import Persistence

struct LearningProgressBar: View {
    let currentIndex: Int
    let size: CGSize
    let context: NSManagedObjectContext
    
    @State private var highGoal: Int = 5
    @State private var characterGroup: [String] = [] // Pre-fetched group of 7 characters (2 old + 5 upcoming)
    @State private var groupStartIndex: Int = 0 // Starting index of the current group
    
    var body: some View {
        VStack(spacing: 6) {
            // Current index below next bubble
            HStack {
                ForEach(0..<7, id: \.self) { index in
                    if index < characterGroup.count {
                        let characterIndex = groupStartIndex + index
                        let isLearned = characterIndex < currentIndex
                        let isNextBubble = characterIndex == currentIndex
                        
                        ZStack {
                            Text(characterGroup[index])
                                .font(.system(size: fontSizeForWord(characterGroup[index]), weight: .medium))
                                .foregroundColor(isLearned ? .white : .primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(isLearned ? Color.blue.opacity(0.7) : Color.gray.opacity(0.2))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            
                            // Overlay current index on the bubble
                            if isNextBubble {
                                Text("\(currentIndex)")
                                    .font(.system(size: 6, weight: .medium))
                                    .foregroundColor(.blue)
                                    .offset(y: -20) // Position above the bubble
                            }
                        }
                        .frame(maxWidth: .infinity) // Distribute space evenly
                    }
                }
            }
        }
        .onAppear {
            initializeProgress()
        }
        .onChange(of: currentIndex) { _ in
            updateProgress()
        }
    }
    
    
    private func initializeProgress() {
        // Calculate high goal based on current index (groups of 7)
        let completedCycles = currentIndex / 7
        highGoal = (completedCycles + 1) * 7
        
        // Fetch character group (2 old + 5 upcoming)
        fetchCharacterGroup()
    }
    
    private func updateProgress() {
        print("🔄 LearningProgressBar: updateProgress() called for currentIndex: \(currentIndex)")
        
        // Check if we need to fetch a new group when we've filled all bubbles
        // We fetch new groups when currentIndex reaches the group max index
        let groupMaxIndex = groupStartIndex + 6 // Last index in current group (7 characters: 0-6)
        
        print("🔄 LearningProgressBar: groupStartIndex: \(groupStartIndex), groupMaxIndex: \(groupMaxIndex)")
        
        if currentIndex >= groupMaxIndex {
            print("🔄 LearningProgressBar: Need to fetch new group! currentIndex(\(currentIndex)) >= groupMaxIndex(\(groupMaxIndex))")
            
            // Move to next goal
            highGoal = currentIndex + 7
            print("🔄 LearningProgressBar: Updated highGoal to \(highGoal)")

            // Fetch new character group for the new cycle
            fetchCharacterGroup()
        } else {
            print("🔄 LearningProgressBar: No need to fetch new group yet")
        }
    }
    
    
    private func fetchCharacterGroup() {
        print("🔄 LearningProgressBar: fetchCharacterGroup() called for currentIndex: \(currentIndex)")
        
        // Fetch 7 characters: 2 old + 5 upcoming
        let i = currentIndex
        let startIndex = max(1, i - 1) // Start 1 character back to show some learned characters
        
        print("🔄 LearningProgressBar: Fetching characters from index \(startIndex) to \(startIndex + 6)")
        
        // Use Task to make this asynchronous and avoid blocking the UI
        Task {
            await context.perform {
                var characters: [String] = []
                
                // Fetch 7 characters starting from startIndex
                for offset in 0..<7 {
                    let wordIndex = Int64(startIndex + offset)
                    if let word = Word.fetchWord(at: wordIndex, context: self.context) {
                        characters.append(word.traditional)
                        print("🔄 LearningProgressBar: Fetched word \(word.traditional) at index \(wordIndex)")
                    } else {
                        characters.append("字")
                        print("⚠️ LearningProgressBar: No word found at index \(wordIndex), using placeholder")
                    }
                }
                
                // Update UI on main actor
                Task { @MainActor in
                    self.characterGroup = characters
                    self.groupStartIndex = startIndex
                    print("🔄 LearningProgressBar: Group updated with \(characters.count) characters, startIndex: \(startIndex)")
                }
            }
        }
    }
    
    private func fontSizeForWord(_ word: String) -> CGFloat {
        let characterCount = word.count
        switch characterCount {
        case 1...2:
            return 18
        case 3:
            return 16
        case 4...:
            return 14
        default:
            return 18
        }
    }
}

#Preview {
    LearningProgressBar(
        currentIndex: 10904, 
        size: CGSize(width: 300, height: 100),
        context: PersistenceController.shared.context
    )
    .padding()
}
