import SwiftUI

struct TowerTodayView: View {
    @EnvironmentObject var store: TowerStore
    @State private var now = Date()
    @State private var openRing = false
    @State private var showRank = false
    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var dayIndex: Int { TowerStore.todayIndex }

    private var dailyMethod: RingingMethod {
        var dice = TowerDice(UInt64(abs(dayIndex &* 2654435761 &+ 41)))
        return MethodBook.all[Int(dice.next() % UInt64(MethodBook.all.count))]
    }

    private var dailyBell: Int {
        var dice = TowerDice(UInt64(abs(dayIndex &* 40503 &+ 7)))
        return 1 + Int(dice.next() % UInt64(dailyMethod.bells))
    }

    private var hour: Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: now)
        return Double(c.hour ?? 12) + Double(c.minute ?? 0) / 60.0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                RisingCard(index: 0) { dailyCard }
                RisingCard(index: 1) { streakCard }
                RisingCard(index: 2) { rankCard }
                RisingCard(index: 3) { noteCard }
                Color.clear.frame(height: 10)
            }
            .padding(.horizontal, Frame.gutter)
            .padding(.top, 8).padding(.bottom, 16)
            .centreColumn()
        }
        .towerPage()
        .navigationBarHidden(true)
        .onReceive(ticker) { now = $0 }
        .fullScreenCover(isPresented: $openRing) {
            RingingView(method: dailyMethod, bell: dailyBell, isDaily: true) { openRing = false }
                .environmentObject(store)
        }
        .sheet(isPresented: $showRank) {
            TowerRankSheet { showRank = false }.environmentObject(store)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ROPE & ROUNDS").font(Cut.title(12)).tracking(3.2).foregroundColor(Belfry.rust)
            Text(longDate).font(Cut.title(25)).foregroundColor(Belfry.ink)
            Text(towerLight(hour: hour).name.lowercased() + " over the belfry")
                .font(Cut.italic(14)).foregroundColor(Belfry.inkPale)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var longDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "EEEE d MMMM"
        return f.string(from: now)
    }

    private var dailyCard: some View {
        let done = store.dailyIsDone(dayIndex)
        let m = dailyMethod
        return VStack(spacing: 0) {
            TowerHeaderScene(hour: hour, bells: m.bells)
                .frame(height: 186)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TODAY'S TOUCH")
                            .font(Cut.title(10)).tracking(2.4).foregroundColor(Belfry.bone.opacity(0.9))
                        Text(m.name).font(Cut.title(20)).foregroundColor(Belfry.paper)
                        Text("on the \(ordinal(dailyBell)) of \(m.bells)")
                            .font(Cut.italic(12)).foregroundColor(Belfry.bone.opacity(0.8))
                    }
                    .padding(14)
                }
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 10) {
                if done {
                    HStack(spacing: 10) {
                        CheckGlyph(size: 20, color: Belfry.moss)
                        Text("Rung and stood.").font(Cut.title(16)).foregroundColor(Belfry.ink)
                        Spacer()
                    }
                    Text("One touch a day, and the bell chosen for you. Tomorrow the tower calls another.")
                        .font(Cut.body(14)).foregroundColor(Belfry.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    FieldButton(title: "Take hold again", tint: Belfry.sepia, filled: false) {
                        openRing = true
                    }
                } else {
                    Text(m.note).font(Cut.italic(15)).foregroundColor(Belfry.ink)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                    FieldButton(title: "Go up to the chamber",
                                subtitle: "\(m.classification) · \(m.stage.title)",
                                tint: Belfry.rust) { openRing = true }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Belfry.card)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Belfry.hairline, lineWidth: 1))
                .shadow(color: Belfry.shadow, radius: 8, x: 0, y: 4)
        )
    }

    private var streakCard: some View {
        TowerCard {
            HStack(spacing: 14) {
                TowerGlyph(size: 30, color: store.liveStreak > 0 ? Belfry.rust : Belfry.inkPale)
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.liveStreak > 0
                         ? "\(store.liveStreak) day\(store.liveStreak == 1 ? "" : "s") in the tower"
                         : "The ropes are up")
                        .font(Cut.title(17)).foregroundColor(Belfry.ink)
                    Text(store.liveStreak > 0
                         ? "Best run so far: \(store.bestStreak) days."
                         : "Ring today's touch to start a run.")
                        .font(Cut.body(13)).foregroundColor(Belfry.inkPale)
                }
                Spacer()
            }
        }
    }

    private var rankCard: some View {
        Button(action: { Strike.tap(); showRank = true }) {
            TowerCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.rank.title.uppercased())
                                .font(Cut.title(13)).tracking(2.2).foregroundColor(Belfry.rust)
                            Text(store.rank.note).font(Cut.italic(13))
                                .foregroundColor(Belfry.inkPale)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 8)
                        Text("\(store.points)").font(Cut.figure(21)).foregroundColor(Belfry.sepia)
                    }
                    ProgressRail(value: store.rankProgress, tint: Belfry.moss)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var noteCard: some View {
        TowerCard(tint: Belfry.cardSunk) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHead(title: "From the tower book")
                Text(noteOfTheDay).font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var noteOfTheDay: String {
        var dice = TowerDice(UInt64(abs(dayIndex &* 15485863 &+ 11)))
        if dice.chance(0.55) {
            let m = MethodBook.all[Int(dice.next() % UInt64(MethodBook.all.count))]
            return "\(m.name). \(m.note)"
        }
        let v = Ring.voices(for: 8)[Int(dice.next() % 8)]
        return "The \(v.name.lowercased()) is tuned to \(v.noteName) and weighs about \(String(format: "%.1f", v.weightCwt)) hundredweight. A bell that size takes roughly \(String(format: "%.1f", v.period)) seconds to go over and come back, which is why you cannot hurry it."
    }

    private func ordinal(_ n: Int) -> String {
        let names = ["treble", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth"]
        return names[max(0, min(names.count - 1, n - 1))]
    }
}

struct TowerRankSheet: View {
    @EnvironmentObject var store: TowerStore
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "The ladder",
                        subtitle: "\(store.points) points · \(store.rank.title)", close: onClose)
            HairRule()
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(TowerRanks.ladder.enumerated()), id: \.offset) { _, r in
                        let reached = store.points >= r.threshold
                        TowerCard(tint: reached ? Belfry.card : Belfry.cardSunk) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(r.title).font(Cut.title(18))
                                        .foregroundColor(reached ? Belfry.ink : Belfry.inkPale)
                                    Spacer()
                                    Text("\(r.threshold)").font(Cut.figure(14))
                                        .foregroundColor(reached ? Belfry.moss : Belfry.inkPale)
                                }
                                Text(r.note).font(Cut.body(14))
                                    .foregroundColor(reached ? Belfry.inkSoft : Belfry.inkPale)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    TowerCard(tint: Belfry.cardSunk) {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionHead(title: "How points come in")
                            Text("Sixty the first time a method comes round, and half the striking on top. Beating your own board pays the difference. Nothing is locked: every method, every bell and every stage is on the board from the first minute.")
                                .font(Cut.body(14)).foregroundColor(Belfry.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
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
