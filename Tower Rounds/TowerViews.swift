import SwiftUI

struct MethodsView: View {
    @EnvironmentObject var store: TowerStore
    @State private var open: RingingMethod? = nil
    @State private var filter: String? = nil

    private var list: [RingingMethod] {
        guard let f = filter else { return MethodBook.all }
        return MethodBook.all.filter { $0.classification == f }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("THE METHODS").font(Cut.title(12)).tracking(3.2).foregroundColor(Belfry.rust)
                    Text("Sixteen to ring").font(Cut.title(25)).foregroundColor(Belfry.ink)
                    Text("\(store.bestByMethod.count) attempted · \(store.bestByMethod.values.filter { $0 >= 80 }.count) struck well")
                        .font(Cut.italic(14)).foregroundColor(Belfry.inkPale)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip(nil, "All")
                        ForEach(MethodBook.classes, id: \.self) { c in chip(c, c) }
                    }
                }
                ForEach(Array(list.enumerated()), id: \.offset) { i, m in
                    RisingCard(index: min(i, 8)) { row(m) }
                }
                Color.clear.frame(height: 10)
            }
            .padding(.horizontal, Frame.gutter)
            .padding(.top, 8)
            .padding(.bottom, 16)
            .centreColumn()
        }
        .towerPage()
        .navigationBarHidden(true)
        .sheet(item: $open) { m in
            MethodDetailView(method: m) { open = nil }.environmentObject(store)
        }
    }

    private func chip(_ value: String?, _ label: String) -> some View {
        Button(action: { Strike.tap(); filter = value }) {
            Text(label)
                .font(Cut.body(13))
                .foregroundColor(filter == value ? Belfry.paper : Belfry.inkSoft)
                .padding(.vertical, 6).padding(.horizontal, 12)
                .background(Capsule().fill(filter == value ? Belfry.sepia : Belfry.cardSunk))
        }
        .buttonStyle(.plain)
    }

    private func row(_ m: RingingMethod) -> some View {
        let best = store.best(for: m.id)
        return Button(action: { Strike.tap(); open = m }) {
            HStack(spacing: 13) {
                BlueLineView(method: m, bell: 2, rowsToShow: 12)
                    .frame(width: 66, height: 62)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Belfry.cardSunk.opacity(0.6)))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(m.name).font(Cut.title(16)).foregroundColor(Belfry.ink)
                    Text("\(m.classification) · \(m.stage.title) · \(generateRows(m, leads: 12).rows.count - 1) changes")
                        .font(Cut.italic(12)).foregroundColor(Belfry.inkPale)
                    HStack(spacing: 5) {
                        ForEach(0..<5, id: \.self) { k in
                            Circle().fill(k < m.difficulty ? Belfry.rust : Belfry.inkPale.opacity(0.22))
                                .frame(width: 5, height: 5)
                        }
                        if let b = best {
                            Text("best \(b)").font(Cut.figure(10))
                                .foregroundColor(b >= 80 ? Belfry.moss : Belfry.inkPale)
                                .padding(.leading, 4)
                        }
                    }
                }
                Spacer()
                ChevronGlyph(size: 14, color: Belfry.inkPale)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Belfry.card))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Belfry.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct MethodDetailView: View {
    let method: RingingMethod
    let onClose: () -> Void
    @EnvironmentObject var store: TowerStore
    @State private var bell = 2
    @State private var openRing = false

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: method.name,
                        subtitle: "\(method.classification) · \(method.stage.title)", close: onClose)
            HairRule()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    PlateImage(name: "meth_" + method.id)

                    HStack(spacing: 10) {
                        StatPill(value: "\(method.difficulty)/5", label: "difficulty", tint: Belfry.rust)
                        StatPill(value: "\(method.bells)", label: "bells")
                        StatPill(value: store.best(for: method.id).map { "\($0)" } ?? "—",
                                 label: "your best", tint: Belfry.moss)
                    }

                    TowerCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHead(title: "The method")
                            Text(method.note).font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    TowerCard(tint: Belfry.cardSunk) {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHead(title: "Rope sight")
                            Text(method.ropeSight).font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    TowerCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHead(title: "Which bell will you ring?",
                                        note: "The treble is easiest in plain methods and hardest in treble bob.")
                            HStack(spacing: 8) {
                                ForEach(1...method.bells, id: \.self) { b in
                                    Button(action: { Strike.tap(); bell = b }) {
                                        VStack(spacing: 2) {
                                            Text("\(b)").font(Cut.figure(17))
                                                .foregroundColor(bell == b ? Belfry.paper : Belfry.ink)
                                            Text(Ring.voices(for: method.bells)[b - 1].noteName)
                                                .font(Cut.body(9))
                                                .foregroundColor(bell == b ? Belfry.paper.opacity(0.8) : Belfry.inkPale)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(bell == b ? Belfry.slate : Belfry.cardSunk))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            BlueLineView(method: method, bell: bell, rowsToShow: 26)
                                .frame(height: 300)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Belfry.cardSunk.opacity(0.5)))
                        }
                    }

                    FieldButton(title: "Take hold",
                                subtitle: "Ringing the \(bell) of \(method.bells)",
                                tint: Belfry.rust) { openRing = true }
                }
                .padding(.horizontal, Frame.gutter)
                .padding(.vertical, 18)
                .centreColumn()
            }
        }
        .towerPage()
        .fullScreenCover(isPresented: $openRing) {
            RingingView(method: method, bell: bell, isDaily: false) { openRing = false }
                .environmentObject(store)
        }
    }
}

struct TowerRoomView: View {
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text("THE TOWER").font(Cut.title(12)).tracking(3.2).foregroundColor(Belfry.rust)
                Text("How a bell works").font(Cut.title(22)).foregroundColor(Belfry.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Frame.gutter)
            .padding(.top, 10).padding(.bottom, 10)
            .background(Belfry.card)
            HairRule()
            Picker("", selection: $page) {
                Text("The ring").tag(0)
                Text("Handling").tag(1)
                Text("Striking").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Frame.gutter)
            .padding(.vertical, 10)
            HairRule()
            ScrollView {
                VStack(alignment: .leading, spacing: 13) {
                    switch page {
                    case 0: ringPage
                    case 1: handlingPage
                    default: strikingPage
                    }
                    Color.clear.frame(height: 12)
                }
                .padding(.horizontal, Frame.gutter)
                .padding(.vertical, 16)
                .centreColumn()
            }
        }
        .towerPage()
        .navigationBarHidden(true)
    }

    private var ringPage: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHead(title: "Eight bells",
                        note: "A ring is tuned as a scale. The tenor is the heaviest and the treble the lightest.")
            ForEach(Ring.voices(for: 8), id: \.index) { v in
                TowerCard {
                    HStack(spacing: 13) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Belfry.cardSunk).frame(width: 54, height: 54)
                            BellGlyph(size: 28, color: Belfry.bell)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(v.name).font(Cut.title(17)).foregroundColor(Belfry.ink)
                            Text("\(v.noteName) · \(String(format: "%.1f", v.weightCwt)) cwt")
                                .font(Cut.figure(12)).foregroundColor(Belfry.sepia)
                            Text("A bell this size takes about \(String(format: "%.1f", v.period)) seconds to swing full circle and back, which is why the tenor always sounds last.")
                                .font(Cut.body(13)).foregroundColor(Belfry.inkPale)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var handlingPage: some View {
        VStack(alignment: .leading, spacing: 12) {
            TowerCard {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHead(title: "Full circle")
                    Text("An English tower bell is not swung like a school bell. It rests mouth upward, balanced just past the top, and a pull on the rope sends it right over through a full turn until it comes to rest mouth upward on the other side. The clapper strikes once as it goes. Everything about the timing follows from that: you are not striking the bell, you are deciding when a quarter of a tonne of bronze arrives.")
                        .font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            TowerCard {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHead(title: "Handstroke and backstroke")
                    Text("The rope comes down twice for every full cycle: once with the woolly sally in your hands, once with the bare tail end. Handstroke and backstroke feel different and sound different, and a band leaves a small extra gap at handstroke — the handstroke gap — which is why change ringing has the rhythm it does and a peal of bells never sounds mechanical.")
                        .font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            TowerCard(tint: Belfry.cardSunk) {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHead(title: "A word of caution")
                    Text("Real bell ropes are dangerous. A rope taken round a wrist or an ankle by a bell that has gone over the balance will break bones. Nobody learns to handle a bell from an app; they learn standing beside somebody who has done it for years.")
                        .font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var strikingPage: some View {
        VStack(alignment: .leading, spacing: 12) {
            TowerCard {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHead(title: "What good striking is")
                    Text("Every blow evenly spaced, with the same gap between each pair of bells all the way down the row. It is entirely a matter of listening: you place your blow after the bell in front of you, not with it. A band that rings the wrong changes with good striking sounds better from the churchyard than a band that rings the right ones badly.")
                        .font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            TowerCard {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHead(title: "Clashing and holes")
                    Text("Two bells that sound together clash, and a listener hears it instantly. A bell that comes late leaves a hole, which is worse — the ear notices absence more than collision. Both come from the same cause: watching the ropes instead of hearing the bells.")
                        .font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            TowerCard {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHead(title: "Why the changes never repeat")
                    Text("A row is a permutation of the bells, and the rule is that no row may be rung twice in a touch and only adjacent bells may swap between rows. On six bells there are 720 possible rows, and ringing all of them is an extent. On twelve there are 479,001,600, which at two hours per ten thousand changes would take about forty years without stopping.")
                        .font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
