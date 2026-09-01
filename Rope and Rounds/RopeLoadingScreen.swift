import SwiftUI

struct RopeLoadingScreen: View {
    @State private var swing = false

    var body: some View {
        ZStack {
            Belfry.paper.ignoresSafeArea()
            VStack(spacing: 24) {
                ZStack {
                    BellGlyph(size: 104, color: Belfry.bell)
                        .rotationEffect(.degrees(swing ? 13 : -13), anchor: .top)
                    RopeGlyph(size: 30, color: Belfry.rust)
                        .offset(y: 62)
                        .opacity(swing ? 1.0 : 0.5)
                }
                .frame(height: 160)

                Text("Rope & Rounds")
                    .font(Cut.title(22))
                    .foregroundColor(Belfry.ink)
                Text("ringing up")
                    .font(Cut.italic(15))
                    .foregroundColor(Belfry.inkPale)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                swing = true
            }
        }
    }
}
