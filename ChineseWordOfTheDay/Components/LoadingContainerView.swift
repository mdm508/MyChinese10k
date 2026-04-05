import SwiftUI

struct LoadingContainerView: View {
    @ObservedObject var loadingManager: LoadingManager
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Loading content
                VStack(spacing: 25) {
                    Text(loadingManager.loadingMessage)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Progress bar with better styling
                    VStack(spacing: 8) {
                        ProgressView(value: loadingManager.loadingProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(width: 250, height: 8)
                            .scaleEffect(y: 1.5)
                        
                        Text("\(Int(loadingManager.loadingProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                }
                
                // Bottom decorative element
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(loadingManager.loadingProgress > Double(index) * 0.3 ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 0.3), value: loadingManager.loadingProgress)
                    }
                }
            }
            .padding(.horizontal, 40)
        }
        .task {
            await loadingManager.initializeApp()
        }
    }
}
