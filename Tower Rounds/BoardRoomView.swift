import SwiftUI

struct PealBoardView: View {
    @EnvironmentObject var store: TowerStore
    @State private var chosen: PealBoard? = nil
    @State private var showAbout = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                RisingCard(index: 0) { stats }
                RisingCard(index: 1) { boardsPanel }
                RisingCard(index: 2) { rankCard }
                RisingCard(index: 3) {
                    FieldButton(title: "About this tower", tint: Belfry.sepia, filled: false) {
                        showAbout = true
                    }
                }
                Color.clear.frame(height: 10)
            }
            .padding(.horizontal, Frame.gutter)
            .padding(.top, 8).padding(.bottom, 16)
            .centreColumn()
        }
        .towerPage()
        .navigationBarHidden(true)
        .sheet(item: $chosen) { b in
            BoardDetailView(record: b) { chosen = nil }.environmentObject(store)
        }
        .sheet(isPresented: $showAbout) {
            TowerAboutSheet { showAbout = false }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("THE RINGING CHAMBER").font(Cut.title(12)).tracking(3.2).foregroundColor(Belfry.rust)
            Text(store.rank.title).font(Cut.title(25)).foregroundColor(Belfry.ink)
            Text(store.rank.note).font(Cut.italic(14)).foregroundColor(Belfry.inkPale)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stats: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatPill(value: "\(store.boards.count)/16", label: "boards", tint: Belfry.rust)
                StatPill(value: "\(Int(store.striking * 100))%", label: "clean blows", tint: Belfry.moss)
                StatPill(value: "\(store.liveStreak)", label: "day run", tint: Belfry.amber)
            }
            HStack(spacing: 10) {
                StatPill(value: "\(store.changesRung)", label: "changes rung")
                StatPill(value: "\(store.blowsStruck)", label: "blows struck")
                StatPill(value: "\(store.bestStreak)", label: "best run")
            }
        }
    }

    private var boardsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                SurfaceLayer(name: "bg_leather", fallback: Belfry.oak)
                    .frame(height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.45), lineWidth: 1.4))
                VStack(alignment: .leading, spacing: 3) {
                    Text("THE PEAL BOARDS")
                        .font(Cut.title(13)).tracking(3.0).foregroundColor(Belfry.amber)
                    Text(store.boards.isEmpty
                         ? "Bare walls. A board goes up for each method you bring round."
                         : "\(store.boards.count) hung on the wall")
                        .font(Cut.italic(13)).foregroundColor(Belfry.bone.opacity(0.85))
                }
                .padding(14)
            }

            if store.boards.isEmpty {
                NoticeBanner(title: "No boards yet",
                             message: "When a touch comes round, the tower paints a board and hangs it in the ringing chamber: the method, the number of changes, the date and the striking. Better striking on the same method repaints the board.",
                             tint: Belfry.amber)
            } else {
                ForEach(store.boards) { b in
                    Button(action: { Strike.tap(); chosen = b }) { boardCard(b) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func boardCard(_ b: PealBoard) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.106, green: 0.129, blue: 0.114),
                                              Color(red: 0.055, green: 0.075, blue: 0.063)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Color.black.opacity(0.28), radius: 5, x: 0, y: 3)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Belfry.amber.opacity(0.75), lineWidth: 2)
                .padding(6)
            VStack(spacing: 5) {
                Text((b.method?.name ?? "Method").uppercased())
                    .font(Cut.title(15)).tracking(1.8).foregroundColor(Belfry.amber)
                    .multilineTextAlignment(.center)
                Rectangle().fill(Belfry.amber.opacity(0.6)).frame(width: 60, height: 1)
                Text("\(b.changes) CHANGES")
                    .font(Cut.figure(12)).foregroundColor(Belfry.bone)
                Text("Rung on the \(ordinal(b.bellRung)) · \(b.minutes) min")
                    .font(Cut.italic(11)).foregroundColor(Belfry.bone.opacity(0.75))
                Text(dayLabel(b.dayIndex))
                    .font(Cut.italic(11)).foregroundColor(Belfry.bone.opacity(0.6))
                Text(b.gradeName)
                    .font(Cut.title(11)).tracking(1.2)
                    .foregroundColor(b.accuracy >= 80 ? Belfry.moss : Belfry.sally)
            }
            .padding(16)
        }
        .frame(height: 168)
    }

    private var rankCard: some View {
        TowerCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(store.rank.title.uppercased())
                        .font(Cut.title(13)).tracking(2.2).foregroundColor(Belfry.rust)
                    Spacer()
                    Text("\(store.points)").font(Cut.figure(20)).foregroundColor(Belfry.sepia)
                }
                ProgressRail(value: store.rankProgress, tint: Belfry.moss)
                if let n = store.nextRank {
                    Text("\(n.threshold - store.points) to \(n.title)")
                        .font(Cut.body(12)).foregroundColor(Belfry.inkPale)
                } else {
                    Text("The ladder is finished. The bells are not.")
                        .font(Cut.body(12)).foregroundColor(Belfry.inkPale)
                }
            }
        }
    }

    private func ordinal(_ n: Int) -> String {
        let names = ["treble", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth"]
        return names[max(0, min(names.count - 1, n - 1))]
    }

    private func dayLabel(_ index: Int) -> String {
        let date = Date(timeIntervalSince1970: TowerStore.epoch + Double(index) * 86_400)
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: date)
    }
}

struct BoardDetailView: View {
    let record: PealBoard
    let onClose: () -> Void
    @EnvironmentObject var store: TowerStore

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: record.method?.name ?? "Touch",
                        subtitle: "\(record.changes) changes · \(record.gradeName)", close: onClose)
            HairRule()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 10) {
                        StatPill(value: "\(record.accuracy)", label: "striking", tint: Belfry.rust)
                        StatPill(value: "\(record.changes)", label: "changes")
                        StatPill(value: "\(record.minutes) min", label: "took", tint: Belfry.sepia)
                    }
                    if let m = record.method {
                        TowerCard {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHead(title: "The method")
                                Text(m.note).font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        TowerCard(tint: Belfry.cardSunk) {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHead(title: "The line you rang")
                                BlueLineView(method: m, bell: record.bellRung, rowsToShow: 26)
                                    .frame(height: 300)
                            }
                        }
                    }
                    if record.accuracy < 92 {
                        NoticeBanner(title: "The board can be repainted",
                                     message: "Ring the same method again with cleaner striking and the tower paints a new board over the old one. Nothing here records the changes you rang — only how well you struck them.",
                                     tint: Belfry.amber)
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

struct TowerAboutSheet: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "About this tower",
                        subtitle: "Tower Rounds · version 1.0", close: onClose)
            HairRule()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    TowerCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHead(title: "What this is")
                            Text("Change ringing is four hundred years old and is not music in the usual sense: it is the systematic permutation of a set of bells, one adjacent swap at a time, with no row repeated. Every method here is stored as its real place notation and the rows are generated from it, so the line you follow is the line the Central Council publishes. The blue line, the place bells and the lead ends are all computed, not drawn.")
                                .font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    TowerCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHead(title: "How to ring")
                            Text("You have one bell. The band rings the others. Pull on every blow, at the moment your bell should sound in the row, and the app measures how far out you were in milliseconds. Your place changes every row according to the method, so the interval between your blows is never quite the same twice — which is the whole difficulty and the whole point.")
                                .font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    TowerCard(tint: Belfry.cardSunk) {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHead(title: "Silent")
                            Text("This app makes no sound. Bells are loud, phones are not, and a tinny bell is worse than none — so the striking is shown rather than heard, on the row strip and on the chart afterwards. If you want the sound, go and stand under a tower on a Sunday evening.")
                                .font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    TowerCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHead(title: "Privacy")
                            Text("Nothing leaves this device. Tower Rounds has no account, no network code and no analytics. Your boards, your striking and your daily log live only in this app's own storage on this iPhone, and go with it if you delete the app. No permissions are requested — no microphone, no camera, no location, no notifications. It works offline because it has never been anything else.")
                                .font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
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
