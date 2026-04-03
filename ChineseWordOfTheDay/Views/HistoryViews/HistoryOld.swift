//    import SwiftUI
//    import CoreData
//    import CoreDataModels
//
//    struct HistoryView: View {
//        @FetchRequest(
//            entity: WordStatus.entity(),
//            sortDescriptors: [NSSortDescriptor(keyPath: \WordStatus.lastModified, ascending: false)]
//        ) var wordStatuses: FetchedResults<WordStatus>
//
//        // 3 columns, perfectly square and flexible
//        private let columns = [
//            GridItem(.flexible(), spacing: 16),
//            GridItem(.flexible(), spacing: 16),
//            GridItem(.flexible(), spacing: 16)
//        ]
//
//        var body: some View {
//            NavigationView {
//                ZStack {
//                    ScrollView {
//                        LazyVGrid(columns: columns, spacing: 16) {
//                            ForEach(wordStatuses) { item in
//                                HistoryCard(status: item)
//                            }
//                        }
//                        .padding()
//                    }
//
//                    if wordStatuses.isEmpty {
//                        emptyState
//                    }
//                }
//                .navigationTitle("History")
//                .background(Color(uiColor: .systemGroupedBackground))
//            }
//            .navigationViewStyle(.stack)
//        }
//        
//        private var emptyState: some View {
//            VStack(spacing: 20) {
//                Image(systemName: "clock.arrow.circlepath")
//                    .font(.largeTitle)
//                    .foregroundColor(.secondary)
//                Text("No History Yet")
//                    .font(.headline)
//            }
//        }
//    }
//
//    struct HistoryCard: View {
//        let status: WordStatus
//        @Environment(\.managedObjectContext) var viewContext
//        
//        @State private var isFlipped = false
//        @State private var detailedWord: Word? = nil
//        @State private var displayMeaning: String = ""
//
//        private var dateFormatter: DateFormatter {
//            let formatter = DateFormatter()
//            formatter.dateStyle = .short
//            return formatter
//        }
//
//        var body: some View {
//            // The outer ZStack is the "Physical Card"
//            ZStack {
//                // --- FRONT SIDE ---
//                VStack {
//                    Spacer()
//                    Text(status.traditional)
//                        .font(.system(.largeTitle, design: .serif))
//                        .fontWeight(.medium)
//                        .lineLimit(1)
//                        .minimumScaleFactor(0.1)
//                    
//                    if let date = status.lastModified {
//                        Text(dateFormatter.string(from: date))
//                            .font(.caption2)
//                            .foregroundColor(.secondary)
//                    }
//                    Spacer()
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill the square
//                .background(Color(uiColor: .secondarySystemGroupedBackground))
//                .opacity(isFlipped ? 0 : 1)
//
//                // --- BACK SIDE ---
//                VStack(spacing: 6) {
//                    if let word = detailedWord {
//                        Spacer(minLength: 0)
//                        
//                        Text(word.phonetic)
//                            .font(.subheadline.bold())
//                            .foregroundColor(.blue)
//                            .lineLimit(1)
//                            .minimumScaleFactor(0.5)
//
//                        Text(displayMeaning)
//                            .font(.caption)
//                            .multilineTextAlignment(.center)
//                            .lineLimit(3)
//                            .minimumScaleFactor(0.5)
//                            .padding(.horizontal, 8)
//                        
//                        Spacer(minLength: 0)
//                        
//                        Text("#\(word.index)")
//                            .font(.system(size: 8, weight: .light, design: .monospaced))
//                            .foregroundColor(.secondary.opacity(0.8))
//                            .padding(.bottom, 4)
//                    } else {
//                        ProgressView()
//                    }
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill the square
//                .background(Color(uiColor: .secondarySystemGroupedBackground))
//                // Rotate the content so it's not mirrored when the card flips
//                .rotation3DEffect(.degrees(180), axis: (y: 1, x: 0, z: 0))
//                .opacity(isFlipped ? 1 : 0)
//            }
//            // LOCK THE SIZE HERE
//            .aspectRatio(1, contentMode: .fit)
//            .frame(maxWidth: .infinity)
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
//            )
//            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
//            // APPLY ROTATION TO THE WHOLE CARD
//            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (y: 1, x: 0, z: 0))
//            .onTapGesture {
//                handleTap()
//            }
//        }
//
//        private func handleTap() {
//            if detailedWord == nil {
//                let request: NSFetchRequest<Word> = Word.fetchRequest()
//                request.predicate = NSPredicate(format: "traditional == %@", status.traditional)
//                request.fetchLimit = 1
//                
//                if let result = try? viewContext.fetch(request).first {
//                    self.detailedWord = result
//                    self.displayMeaning = result.meanings.randomElement() ?? ""
//                }
//            }
//            
//            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
//                isFlipped.toggle()
//            }
//        }
//    }
