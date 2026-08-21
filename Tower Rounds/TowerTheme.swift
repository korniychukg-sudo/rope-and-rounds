import SwiftUI

enum Belfry {
    static let paper = Color(red: 0.937, green: 0.922, blue: 0.882)
    static let paperDeep = Color(red: 0.886, green: 0.867, blue: 0.816)
    static let card = Color(red: 0.976, green: 0.965, blue: 0.941)
    static let cardSunk = Color(red: 0.906, green: 0.890, blue: 0.855)

    static let ink = Color(red: 0.129, green: 0.122, blue: 0.118)
    static let inkSoft = Color(red: 0.278, green: 0.263, blue: 0.251)
    static let inkPale = Color(red: 0.463, green: 0.443, blue: 0.427)

    static let sepia = Color(red: 0.322, green: 0.259, blue: 0.204)
    static let rust = Color(red: 0.545, green: 0.267, blue: 0.192)
    static let moss = Color(red: 0.278, green: 0.373, blue: 0.322)
    static let amber = Color(red: 0.749, green: 0.588, blue: 0.235)
    static let slate = Color(red: 0.365, green: 0.396, blue: 0.435)
    static let bone = Color(red: 0.882, green: 0.863, blue: 0.804)
    static let night = Color(red: 0.075, green: 0.078, blue: 0.086)
    static let bell = Color(red: 0.545, green: 0.443, blue: 0.243)
    static let bellLit = Color(red: 0.808, green: 0.694, blue: 0.427)
    static let bellDeep = Color(red: 0.294, green: 0.216, blue: 0.106)
    static let sally = Color(red: 0.671, green: 0.259, blue: 0.239)
    static let ropeTone = Color(red: 0.792, green: 0.741, blue: 0.639)
    static let oak = Color(red: 0.322, green: 0.235, blue: 0.161)

    static let hairline = Color(red: 0.129, green: 0.122, blue: 0.118).opacity(0.16)
    static let shadow = Color(red: 0.129, green: 0.122, blue: 0.118).opacity(0.10)
}

enum Cut {
    static func title(_ size: CGFloat) -> Font { .custom("Georgia-Bold", size: size) }
    static func body(_ size: CGFloat) -> Font { .custom("Georgia", size: size) }
    static func italic(_ size: CGFloat) -> Font { .custom("Georgia-Italic", size: size) }
    static func figure(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .monospaced) }
}

enum Frame {
    static var isPad: Bool { UIScreen.main.bounds.width >= 700 }
    static var contentWidth: CGFloat { isPad ? 660 : UIScreen.main.bounds.width }
    static var gutter: CGFloat { isPad ? 32 : 18 }
    static var screenH: CGFloat { UIScreen.main.bounds.height }
}

struct SurfaceLayer: View {
    let name: String
    var fallback: Color
    var opacity: Double = 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                fallback
                if let ui = plateFromBundle(name) {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .opacity(opacity)
                }
            }
        }
    }
}

extension View {
    func towerPage() -> some View {
        self.background(
            SurfaceLayer(name: "bg_paper", fallback: Belfry.paper)
                .ignoresSafeArea()
        )
    }

    func centreColumn() -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            self.frame(maxWidth: Frame.contentWidth)
            Spacer(minLength: 0)
        }
    }
}

enum Strike {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func firm() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}
