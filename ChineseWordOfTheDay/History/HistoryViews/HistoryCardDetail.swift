import SwiftUI
import CoreData
import CoreDataModels

struct HistoryCardDetail: View {
    // 🔥 NEW: Pass the managed object and the context
    let status: WordStatus
    let context: NSManagedObjectContext
    var isStreamMode: Bool = false
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var speechVM = SpeechViewModel()

    // MARK: - Computed Data
    // Fetch the word data lazily using the indexed bridge
    private var word: Word? {
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        request.predicate = NSPredicate(format: "index == %d", status.index)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    var body: some View {
        if isStreamMode {
            detailContent
        } else {
            NavigationView {
                detailContent
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { dismiss() }
                                .font(.system(size: 17, weight: .bold))
                        }
                    }
            }
        }
    }

    // --- 🧬 THE UNIFIED GUTS ---
    private var detailContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                
                // 1. --- 🐲 HERO SECTION ---
                VStack(spacing: 16) {
                    let chars = word?.characters ?? ""
                    
                    Text(chars)
                        .font(.system(size: 110, weight: .bold, design: .serif))
                        .foregroundColor(speechVM.isSpeaking ? .blue : .primary)
                        .scaleEffect(speechVM.isSpeaking ? 1.05 : 1.0)
                        .shadow(color: speechVM.isSpeaking ? .blue.opacity(0.15) : .clear, radius: 10)
                        .onTapGesture {
                            speechVM.speak(chars, .chineseTaiwan)
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                    
                    VStack(spacing: 4) {
                        Text(word?.phonetic ?? "")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        if speechVM.isSpeaking {
                            Text("Speaking...")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.blue)
                                .transition(.opacity)
                        }
                    }
                }
                .padding(.vertical, 50)
                .frame(maxWidth: .infinity)
                .background(Color.primary.opacity(0.02))
                
                Divider()

                // 2. --- 📝 DATA SECTION ---
                VStack(alignment: .leading, spacing: 30) {
                    detailRow(title: "Meanings", content: meaningsList)
                    
                    Divider().opacity(0.5)
                    
                    HStack(alignment: .top) {
                        detailRow(title: "Index", content: Text("#\(status.index)"))
                        Spacer()
                        detailRow(title: "Learned", content: Text(formattedDate))
                    }
                }
                .padding(30)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(32)
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .padding(.top, isStreamMode ? 0 : 20)
            .padding(.bottom, isStreamMode ? 100 : 20)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: speechVM.isSpeaking)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Subviews
    
    private var meaningsList: some View {
        // Assume meanings is an array of strings on your Word entity
        let meanings = word?.meanings ?? []
        
        return VStack(alignment: .leading, spacing: 14) {
            ForEach(meanings.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(i + 1).")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.blue.opacity(0.5))
                    
                    Text(meanings[i])
                        .font(.system(size: 19, weight: .medium, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private var formattedDate: String {
        guard let date = status.lastModified else { return "Unknown" }
        let df = DateFormatter()
        df.dateFormat = "MMMM d, yyyy"
        return df.string(from: date)
    }

    private func detailRow<Content: View>(title: String, content: Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.secondary.opacity(0.6))
                .kerning(1.2)
            content
        }
    }
}
