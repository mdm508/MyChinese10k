import SwiftUI

/// `HistoryWordView` is a specialized renderer for the History Grid.
/// It uses 'greedy' scaling to fill the card face without needing GeometryReader.
struct HistoryWordView: View {
    let text: String
    let idealFontSize: CGFloat = 80
    
    var body: some View {
        Text(text)
            .font(.system(size: idealFontSize, weight: .regular, design: .monospaced))
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.2)
            .lineLimit(1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(13)
    }
}

// MARK: - Preview
struct HistoryWordView_Previews: PreviewProvider {
    static var previews: some View {
        // Testing with the New Year Pun: "馬到成功" (Success comes instantly)
        HistoryWordView(text: "馬到成功")
            .frame(width: 140, height: 140)
            .background(Color.orange.opacity(0.1)) // Festive orange/gold tint
            .cornerRadius(16)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
