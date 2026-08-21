import SwiftUI

struct RingingView: View {
    let method: RingingMethod
    let bell: Int
    let isDaily: Bool
    let onClose: () -> Void

    @EnvironmentObject var store: TowerStore
    @StateObject private var session: RingSession
    @State private var showResult = false
    @State private var showLine = false

    init(method: RingingMethod, bell: Int, isDaily: Bool, onClose: @escaping () -> Void) {
        self.method = method
        self.bell = bell
        self.isDaily = isDaily
        self.onClose = onClose
        _session = StateObject(wrappedValue: RingSession(method: method, bell: bell, isDaily: isDaily))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            GeometryReader { geo in
                ZStack {
                    SurfaceLayer(name: "bg_leather", fallback: Belfry.oak).opacity(0.85)
                    body(size: geo.size)
                }
            }
            rowStrip
            controls
        }
        .towerPage()
        .overlay(alignment: .top) { noteLayer }
        .sheet(isPresented: $showLine) {
            LineSheet(method: method, bell: bell) { showLine = false }
        }
        .sheet(isPresented: $showResult) {
            RingResultSheet(session: session, onClose: { showResult = false; onClose() })
                .environmentObject(store)
        }
        .onChange(of: session.stage) { s in
            if s == .stood { finish() }
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: { Strike.tap(); onClose() }) {
                    ChevronGlyph(size: 16, color: Belfry.inkSoft, facing: .pi)
                        .padding(9).background(Circle().fill(Belfry.cardSunk))
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.name).font(Cut.title(18)).foregroundColor(Belfry.ink)
                    Text("Ringing the \(ordinal(bell)) · \(session.changesRung) changes")
                        .font(Cut.italic(12)).foregroundColor(Belfry.inkPale)
                }
                Spacer()
                Button(action: { Strike.tap(); showLine = true }) {
                    Text("The line")
                        .font(Cut.title(13)).foregroundColor(Belfry.rust)
                        .padding(.vertical, 7).padding(.horizontal, 12)
                        .background(Capsule().stroke(Belfry.rust.opacity(0.5), lineWidth: 1.2))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Frame.gutter)
            .padding(.vertical, 10)
            HairRule()
        }
        .background(Belfry.card)
    }

    private func body(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: session.stage != .ringing)) { tl in
            let _ = tl.date
            VStack(spacing: 0) {
                BellWheelView(angle: session.wheelAngle,
                              voice: session.voices[min(bell - 1, session.voices.count - 1)],
                              striking: session.strikingFlash)
                    .frame(height: size.height * 0.46)
                RopeView(pull: session.pull, atHandstroke: session.handstroke)
                    .frame(height: size.height * 0.50)
            }
            .frame(width: size.width, height: size.height)
            .onChange(of: tl.date) { d in session.tick(d) }
        }
    }

    private var rowStrip: some View {
        VStack(spacing: 0) {
            HairRule()
            Canvas { ctx, size in
                let n = method.bells
                let w = size.width / CGFloat(n)
                let row = session.run.rows[min(session.rowIndex, session.run.rows.count - 1)]
                var i = 0
                while i < n {
                    let x = (CGFloat(i) + 0.5) * w
                    let b = row[i]
                    let mine = b == session.myBell
                    let flash = session.otherFlash[b] ?? 0
                    var box = Path()
                    box.addRoundedRect(in: CGRect(x: x - w * 0.40, y: 8,
                                                  width: w * 0.80, height: size.height - 16),
                                       cornerSize: CGSize(width: 6, height: 6))
                    ctx.fill(box, with: .color(mine ? Belfry.slate
                                               : Belfry.cardSunk.opacity(0.5 + 0.5 * flash)))
                    if mine && session.strikingFlash > 0 {
                        ctx.stroke(box, with: .color(Belfry.amber.opacity(session.strikingFlash)),
                                   lineWidth: 2.4)
                    }
                    ctx.draw(Text("\(b)")
                                .font(Cut.figure(17))
                                .foregroundColor(mine ? Belfry.paper : Belfry.ink),
                             at: CGPoint(x: x, y: size.height / 2))
                    i += 1
                }
            }
            .frame(height: 52)
            .padding(.horizontal, Frame.gutter)
            .padding(.vertical, 6)
        }
        .background(Belfry.card)
    }

    private var controls: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack(spacing: 10) {
                StatPill(value: "\(session.myPlace)", label: "your place", tint: Belfry.slate)
                StatPill(value: "\(session.nextPlace)", label: "next", tint: Belfry.inkPale)
                StatPill(value: "\(session.accuracy)", label: "striking", tint: Belfry.rust)
                if session.stage == .standing {
                    Button(action: { Strike.firm(); session.start() }) {
                        Text("Look to")
                            .font(Cut.title(15)).foregroundColor(Belfry.paper)
                            .padding(.vertical, 11).padding(.horizontal, 18)
                            .background(Capsule().fill(Belfry.rust))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: { Strike.firm(); session.stage = .stood }) {
                        Text("Stand")
                            .font(Cut.title(15)).foregroundColor(Belfry.paper)
                            .padding(.vertical, 11).padding(.horizontal, 18)
                            .background(Capsule().fill(Belfry.sepia))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Frame.gutter)
            .padding(.vertical, 8)

            Button(action: { session.strikeNow(store: store) }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(session.stage == .ringing ? Belfry.sally : Belfry.inkPale.opacity(0.4))
                    VStack(spacing: 2) {
                        Text(session.handstroke ? "HANDSTROKE" : "BACKSTROKE")
                            .font(Cut.title(12)).tracking(2.6).foregroundColor(Belfry.paper.opacity(0.9))
                        Text("Pull").font(Cut.title(22)).foregroundColor(Belfry.paper)
                    }
                }
                .frame(height: 74)
            }
            .buttonStyle(.plain)
            .disabled(session.stage != .ringing)
            .padding(.horizontal, Frame.gutter)
            .padding(.bottom, 10)
        }
        .background(
            SurfaceLayer(name: "bg_canvas", fallback: Belfry.card)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private var noteLayer: some View {
        Group {
            if let n = session.note {
                Text(n)
                    .font(Cut.body(12))
                    .foregroundColor(Belfry.paper)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8).padding(.horizontal, 14)
                    .background(Capsule().fill(Belfry.night.opacity(0.88)))
                    .padding(.top, 62)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                    .onTapGesture { session.note = nil }
            }
        }
        .animation(.easeOut(duration: 0.22), value: session.note)
    }

    private func ordinal(_ n: Int) -> String {
        let names = ["treble", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth"]
        return names[max(0, min(names.count - 1, n - 1))]
    }

    private func finish() {
        guard !showResult else { return }
        Strike.heavy()
        let acc = session.accuracy
        store.record(method: method, changes: session.changesRung, accuracy: acc,
                     minutes: max(1, Int(Double(session.changesRung) * session.blowInterval
                                         * Double(method.bells) / 60.0)),
                     bell: bell)
        if isDaily { store.noteDaily(day: TowerStore.todayIndex, accuracy: acc) }
        showResult = true
    }
}

struct LineSheet: View {
    let method: RingingMethod
    let bell: Int
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: method.name,
                        subtitle: "The line for the \(bell)", close: onClose)
            HairRule()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BlueLineView(method: method, bell: bell, rowsToShow: 40)
                        .frame(height: 520)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Belfry.card))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Belfry.hairline, lineWidth: 1))
                    TowerCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHead(title: "Rope sight")
                            Text(method.ropeSight).font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    TowerCard(tint: Belfry.cardSunk) {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHead(title: "Place notation")
                            Text(expandNotation(method.notation).joined(separator: " · "))
                                .font(Cut.figure(14)).foregroundColor(Belfry.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Lead end: \(method.leadEnd)")
                                .font(Cut.figure(13)).foregroundColor(Belfry.inkPale)
                        }
                    }
                }
                .padding(.horizontal, Frame.gutter)
                .padding(.vertical, 18)
                .centreColumn()
            }
        }
        .towerPage()
    }
}

struct RingResultSheet: View {
    @ObservedObject var session: RingSession
    let onClose: () -> Void
    @EnvironmentObject var store: TowerStore

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: grade,
                        subtitle: "\(session.changesRung) changes of \(session.method.name)",
                        close: onClose)
            HairRule()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 10) {
                        StatPill(value: "\(session.accuracy)", label: "striking", tint: Belfry.rust)
                        StatPill(value: "\(session.marks.filter { $0.clean }.count)/\(session.marks.count)",
                                 label: "clean blows", tint: Belfry.moss)
                        StatPill(value: "\(session.changesRung)", label: "changes")
                    }

                    TowerCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHead(title: "Where your blows fell")
                            StrikingChart(marks: session.marks)
                                .frame(height: 150)
                        }
                    }

                    TowerCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHead(title: "What the band heard")
                            Text(verdict).font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    FieldButton(title: "Onto the board", tint: Belfry.rust) { onClose() }
                }
                .padding(.horizontal, Frame.gutter)
                .padding(.vertical, 18)
                .centreColumn()
            }
        }
        .towerPage()
    }

    private var grade: String {
        switch session.accuracy {
        case 92...: return "Struck like a clock"
        case 80..<92: return "Good striking"
        case 64..<80: return "Passable"
        case 46..<64: return "Rough"
        default: return "A fire in a brass foundry"
        }
    }

    private var verdict: String {
        let early = session.marks.filter { $0.errorMs < -62 }.count
        let late = session.marks.filter { $0.errorMs > 62 }.count
        if session.accuracy >= 92 {
            return "Even, open and in its place. That is what a good band sounds like from the road outside, and it is far harder than ringing the right changes."
        }
        if early > late * 2 {
            return "You were consistently early — \(early) blows cut into the bell in front. Ringers rush when they are counting the method instead of listening. Listen to the bell before you and put yours after it, not with it."
        }
        if late > early * 2 {
            return "You were consistently late — \(late) blows left a hole. A gap is more audible than a clash, and it is usually a sign of checking the line instead of trusting it."
        }
        return "The errors scatter both ways, which means the rhythm rather than the method is the problem. Ring rounds until the interval is automatic; everything else is built on it."
    }
}

struct StrikingChart: View {
    let marks: [BlowMark]

    var body: some View {
        Canvas { ctx, size in
            var mid = Path()
            mid.move(to: CGPoint(x: 0, y: size.height / 2))
            mid.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            ctx.stroke(mid, with: .color(Belfry.inkPale.opacity(0.5)), lineWidth: 1.2)

            var band = Path()
            let h = size.height * 0.16
            band.addRect(CGRect(x: 0, y: size.height / 2 - h, width: size.width, height: h * 2))
            ctx.fill(band, with: .color(Belfry.moss.opacity(0.14)))

            guard !marks.isEmpty else { return }
            let step = size.width / CGFloat(max(1, marks.count))
            var i = 0
            while i < marks.count {
                let m = marks[i]
                let e = CGFloat(max(-260, min(260, m.errorMs))) / 260.0
                let x = (CGFloat(i) + 0.5) * step
                let y = size.height / 2 + e * size.height * 0.44
                var bar = Path()
                bar.move(to: CGPoint(x: x, y: size.height / 2))
                bar.addLine(to: CGPoint(x: x, y: y))
                ctx.stroke(bar, with: .color(m.clean ? Belfry.moss : Belfry.rust),
                           style: StrokeStyle(lineWidth: max(1.2, step * 0.55), lineCap: .round))
                i += 1
            }
            ctx.draw(Text("early").font(Cut.body(10)).foregroundColor(Belfry.inkPale),
                     at: CGPoint(x: 26, y: 12))
            ctx.draw(Text("late").font(Cut.body(10)).foregroundColor(Belfry.inkPale),
                     at: CGPoint(x: 24, y: size.height - 12))
        }
    }
}
