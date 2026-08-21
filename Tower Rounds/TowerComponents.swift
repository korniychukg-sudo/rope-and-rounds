import SwiftUI

struct TowerDice {
    var s: UInt64
    init(_ seed: UInt64) { s = seed == 0 ? 0x243F6A8885A308D3 : seed }
    mutating func next() -> UInt64 { s ^= s << 13; s ^= s >> 7; s ^= s << 17; return s }
    mutating func unit() -> Double { Double(next() % 1_000_000) / 1_000_000.0 }
    mutating func range(_ a: Double, _ b: Double) -> Double { a + unit() * (b - a) }
    mutating func chance(_ p: Double) -> Bool { unit() < p }
}

struct TowerCard<Content: View>: View {
    var tint: Color = Belfry.card
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint)
                    .overlay(
                        SurfaceLayer(name: "bg_card", fallback: .clear, opacity: 0.62)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .blendMode(.multiply)
                            .allowsHitTesting(false)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Belfry.hairline, lineWidth: 1)
                    )
                    .shadow(color: Belfry.shadow, radius: 6, x: 0, y: 3)
            )
    }
}

struct RisingCard<Content: View>: View {
    let index: Int
    @ViewBuilder var content: () -> Content
    @State private var shown = false

    var body: some View {
        content()
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 16)
            .onAppear {
                withAnimation(.easeOut(duration: 0.42).delay(Double(index) * 0.055)) {
                    shown = true
                }
            }
    }
}

struct SectionHead: View {
    let title: String
    var note: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .leading) {
                Text(title.uppercased())
                    .font(Cut.title(13))
                    .tracking(2.4)
                    .foregroundColor(Belfry.paper.opacity(0.75))
                    .offset(x: 0.6, y: 1.0)
                Text(title.uppercased())
                    .font(Cut.title(13))
                    .tracking(2.4)
                    .foregroundColor(Belfry.rust)
            }
            if let note = note {
                Text(note)
                    .font(Cut.italic(14))
                    .foregroundColor(Belfry.inkPale)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HairRule: View {
    var weight: CGFloat = 1.2
    var tone: Color = Belfry.inkSoft.opacity(0.30)

    var body: some View {
        Canvas { ctx, size in
            var rng = TowerDice(UInt64(size.width * 13) &+ 7)
            var line = Path()
            line.move(to: CGPoint(x: 0, y: size.height / 2))
            var x: CGFloat = 0
            while x < size.width {
                let step = CGFloat(rng.range(18, 46))
                x = min(size.width, x + step)
                line.addLine(to: CGPoint(x: x, y: size.height / 2 + CGFloat(rng.range(-0.7, 0.7))))
            }
            ctx.stroke(line, with: .color(tone),
                       style: StrokeStyle(lineWidth: weight, lineCap: .round))
        }
        .frame(height: max(2, weight + 1))
    }
}

struct PinMark: View {
    var tint: Color = Belfry.rust
    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            var shadow = Path()
            shadow.addEllipse(in: CGRect(x: c.x - size.width * 0.30 + 2,
                                         y: c.y - size.height * 0.30 + 3,
                                         width: size.width * 0.60, height: size.height * 0.60))
            ctx.fill(shadow, with: .color(Color.black.opacity(0.22)))
            var head = Path()
            head.addEllipse(in: CGRect(x: c.x - size.width * 0.30, y: c.y - size.height * 0.30,
                                       width: size.width * 0.60, height: size.height * 0.60))
            ctx.fill(head, with: .radialGradient(
                Gradient(colors: [tint.opacity(0.95), tint.opacity(0.55)]),
                center: CGPoint(x: c.x - size.width * 0.10, y: c.y - size.height * 0.12),
                startRadius: 0, endRadius: size.width * 0.36))
            var gloss = Path()
            gloss.addEllipse(in: CGRect(x: c.x - size.width * 0.20, y: c.y - size.height * 0.22,
                                        width: size.width * 0.18, height: size.height * 0.16))
            ctx.fill(gloss, with: .color(Color.white.opacity(0.55)))
        }
    }
}

struct FieldButton: View {
    let title: String
    var subtitle: String? = nil
    var tint: Color = Belfry.sepia
    var filled: Bool = true
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: { if enabled { Strike.tap(); action() } }) {
            VStack(spacing: 2) {
                Text(title)
                    .font(Cut.title(16))
                    .foregroundColor(filled ? Belfry.paper : tint)
                if let s = subtitle {
                    Text(s)
                        .font(Cut.italic(12))
                        .foregroundColor(filled ? Belfry.paper.opacity(0.82) : tint.opacity(0.75))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(filled ? tint : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(tint.opacity(filled ? 0 : 0.55), lineWidth: 1.4)
                    )
            )
            .opacity(enabled ? 1 : 0.42)
        }
        .buttonStyle(.plain)
    }
}

struct StatPill: View {
    let value: String
    let label: String
    var tint: Color = Belfry.sepia

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Cut.figure(20))
                .foregroundColor(tint)
            Text(label.uppercased())
                .font(Cut.body(10))
                .tracking(1.4)
                .foregroundColor(Belfry.inkPale)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Belfry.cardSunk)
        )
    }
}

struct NoticeBanner: View {
    let title: String
    let message: String
    var tint: Color = Belfry.amber
    var action: (() -> Void)? = nil
    var actionTitle: String = "Open"

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(Cut.title(15)).foregroundColor(Belfry.ink)
                Text(message).font(Cut.body(13)).foregroundColor(Belfry.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 6)
            if let action = action {
                Button(action: { Strike.tap(); action() }) {
                    Text(actionTitle)
                        .font(Cut.title(13))
                        .foregroundColor(Belfry.paper)
                        .padding(.vertical, 7).padding(.horizontal, 13)
                        .background(Capsule().fill(tint.opacity(0.92)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(tint.opacity(0.45), lineWidth: 1)
                )
        )
    }
}

struct SheetHeader: View {
    let title: String
    var subtitle: String? = nil
    let close: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(Cut.title(22)).foregroundColor(Belfry.ink)
                if let s = subtitle {
                    Text(s).font(Cut.italic(14)).foregroundColor(Belfry.inkPale)
                }
            }
            Spacer()
            Button(action: { Strike.tap(); close() }) {
                CrossGlyph(size: 17, color: Belfry.inkSoft)
                    .padding(9)
                    .background(Circle().fill(Belfry.cardSunk))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Frame.gutter)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }
}

struct ProgressRail: View {
    var value: Double
    var tint: Color = Belfry.moss
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Belfry.cardSunk)
                Capsule().fill(tint)
                    .frame(width: max(4, geo.size.width * CGFloat(min(1, max(0, value)))))
            }
        }
        .frame(height: 7)
    }
}

struct PlateImage: View {
    let name: String
    var corner: CGFloat = 12

    var body: some View {
        Group {
            if let ui = UIImage(named: name) ?? plateFromBundle(name) {
                Image(uiImage: ui)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: corner)
                    .fill(Belfry.cardSunk)
                    .aspectRatio(0.7, contentMode: .fit)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Belfry.hairline, lineWidth: 1)
        )
    }
}

private var plateCache: [String: UIImage] = [:]

func plateFromBundle(_ name: String) -> UIImage? {
    if let cached = plateCache[name] { return cached }
    guard let url = Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "Art")
            ?? Bundle.main.url(forResource: name, withExtension: "jpg"),
          let data = try? Data(contentsOf: url),
          let img = UIImage(data: data) else { return nil }
    if plateCache.count > 24 { plateCache.removeAll() }
    plateCache[name] = img
    return img
}
