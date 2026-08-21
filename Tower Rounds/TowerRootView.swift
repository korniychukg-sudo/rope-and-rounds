import SwiftUI

struct PracticeView: View {
    @EnvironmentObject var store: TowerStore
    @State private var methodID = "plainbob5"
    @State private var bell = 2
    @State private var openRing = false

    private var method: RingingMethod { MethodBook.method(methodID) ?? MethodBook.all[0] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PRACTICE NIGHT").font(Cut.title(12)).tracking(3.2).foregroundColor(Belfry.rust)
                    Text("Take a rope").font(Cut.title(25)).foregroundColor(Belfry.ink)
                    Text("Any method, any bell, as long as you like.")
                        .font(Cut.italic(14)).foregroundColor(Belfry.inkPale)
                }

                RisingCard(index: 0) {
                    TowerCard(padding: 12) {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHead(title: "The method")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 9) {
                                    ForEach(MethodBook.all, id: \.id) { m in
                                        Button(action: {
                                            Strike.tap(); methodID = m.id
                                            if bell > m.bells { bell = m.bells }
                                        }) {
                                            VStack(spacing: 4) {
                                                BlueLineView(method: m, bell: 2, rowsToShow: 10)
                                                    .frame(width: 58, height: 56)
                                                    .background(RoundedRectangle(cornerRadius: 6)
                                                        .fill(methodID == m.id ? Belfry.slate.opacity(0.16) : Belfry.cardSunk))
                                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                                Text(m.name).font(Cut.body(9))
                                                    .foregroundColor(methodID == m.id ? Belfry.ink : Belfry.inkPale)
                                                    .lineLimit(1).frame(width: 68)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }

                RisingCard(index: 1) {
                    TowerCard(padding: 12) {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHead(title: "Your bell")
                            HStack(spacing: 8) {
                                ForEach(1...method.bells, id: \.self) { b in
                                    Button(action: { Strike.tap(); bell = b }) {
                                        Text("\(b)").font(Cut.figure(17))
                                            .foregroundColor(bell == b ? Belfry.paper : Belfry.ink)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 11)
                                            .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(bell == b ? Belfry.slate : Belfry.cardSunk))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            BlueLineView(method: method, bell: bell, rowsToShow: 22)
                                .frame(height: 260)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 10)
                                    .fill(Belfry.cardSunk.opacity(0.5)))
                        }
                    }
                }

                RisingCard(index: 2) {
                    FieldButton(title: "Look to",
                                subtitle: "\(method.name) on the \(bell)",
                                tint: Belfry.rust) { openRing = true }
                }

                RisingCard(index: 3) {
                    TowerCard(tint: Belfry.cardSunk) {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHead(title: "Before you pull off")
                            Text("Learn where your bell goes before you take hold. The line above is your path through the rows; the dotted line is the treble, which is the clock the whole band watches. Ring rounds first until the interval is in your hands, then let the method start.")
                                .font(Cut.body(15)).foregroundColor(Belfry.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
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
        .fullScreenCover(isPresented: $openRing) {
            RingingView(method: method, bell: bell, isDaily: false) { openRing = false }
                .environmentObject(store)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: TowerStore
    @State private var tab = 0
    @State private var lastTab = 0

    var body: some View {
        ZStack {
            if store.onboarded { mainShell }
            else { OnboardingView { store.markOnboarded() }.transition(.opacity) }
        }
        .animation(.easeInOut(duration: 0.35), value: store.onboarded)
    }

    private var mainShell: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case 0:
                    NavigationView { TowerTodayView() }.navigationViewStyle(StackNavigationViewStyle())
                case 1:
                    NavigationView { MethodsView() }.navigationViewStyle(StackNavigationViewStyle())
                case 2:
                    NavigationView { PracticeView() }.navigationViewStyle(StackNavigationViewStyle())
                case 3:
                    NavigationView { TowerRoomView() }.navigationViewStyle(StackNavigationViewStyle())
                default:
                    NavigationView { PealBoardView() }.navigationViewStyle(StackNavigationViewStyle())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(tab)
            .transition(.asymmetric(
                insertion: .move(edge: tab > lastTab ? .trailing : .leading).combined(with: .opacity),
                removal: .opacity))
            tabBar
        }
        .towerPage()
    }

    private var tabBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(LinearGradient(colors: [Color.black.opacity(0.18), Color.clear],
                                     startPoint: .bottom, endPoint: .top))
                .frame(height: 8)
            HStack(spacing: 0) {
                tabButton(0, "Today", AnyView(TowerGlyph(size: 21, color: tint(0))))
                tabButton(1, "Methods", AnyView(BookGlyph(size: 21, color: tint(1))))
                tabButton(2, "Practice", AnyView(RopeGlyph(size: 21, color: tint(2))))
                tabButton(3, "Tower", AnyView(BellGlyph(size: 21, color: tint(3))))
                tabButton(4, "Boards", AnyView(BoardGlyph(size: 21, color: tint(4))))
            }
            .padding(.top, 9).padding(.bottom, 3)
            .background(
                SurfaceLayer(name: "bg_canvas", fallback: Belfry.card)
                    .edgesIgnoringSafeArea(.bottom)
            )
        }
    }

    private func tint(_ i: Int) -> Color { tab == i ? Belfry.amber : Belfry.bone.opacity(0.62) }

    private func tabButton(_ index: Int, _ label: String, _ icon: AnyView) -> some View {
        Button(action: {
            guard tab != index else { return }
            Strike.tap()
            lastTab = tab
            withAnimation(.easeInOut(duration: 0.28)) { tab = index }
        }) {
            VStack(spacing: 3) {
                icon
                Text(label).font(Cut.body(10)).foregroundColor(tint(index))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.black.opacity(tab == index ? 0.26 : 0))
                    .padding(.horizontal, 6)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingView: View {
    let onDone: () -> Void
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("A bell goes right over",
         "An English tower bell rests mouth upward and a pull sends it through a full circle. You are not striking it: you are deciding when a quarter of a tonne of bronze arrives.",
         "bell"),
        ("The order changes every row",
         "No row may be rung twice, and only bells next to each other may swap. Sixteen real methods are here as their published place notation, and every row is computed from it.",
         "book"),
        ("Striking is the whole art",
         "Put your blow after the bell in front, evenly, every time. A band that rings the wrong changes with good striking sounds better from the churchyard than one that rings the right ones badly.",
         "rope")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if page > 0 {
                    Button(action: { Strike.tap(); withAnimation { page -= 1 } }) {
                        ChevronGlyph(size: 16, color: Belfry.inkSoft, facing: .pi)
                            .padding(9).background(Circle().fill(Belfry.cardSunk))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button(action: { Strike.tap(); onDone() }) {
                    Text("Skip").font(Cut.title(14)).foregroundColor(Belfry.inkPale)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Frame.gutter).padding(.top, 14)
            Spacer(minLength: 0)
            VStack(spacing: 22) {
                ZStack {
                    Circle().fill(Belfry.cardSunk).frame(width: 168, height: 168)
                    switch pages[page].2 {
                    case "bell": BellGlyph(size: 86, color: Belfry.sepia)
                    case "book": BookGlyph(size: 86, color: Belfry.sepia)
                    default: RopeGlyph(size: 92, color: Belfry.sepia)
                    }
                }
                VStack(spacing: 12) {
                    Text(pages[page].0).font(Cut.title(25)).foregroundColor(Belfry.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(pages[page].1).font(Cut.body(16)).foregroundColor(Belfry.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 26)
            }
            .id(page)
            .transition(.opacity)
            Spacer(minLength: 0)
            HStack(spacing: 7) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Circle().fill(i == page ? Belfry.rust : Belfry.inkPale.opacity(0.35))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.bottom, 18)
            FieldButton(title: page == pages.count - 1 ? "Up to the chamber" : "Next",
                        tint: Belfry.rust) {
                if page == pages.count - 1 { onDone() }
                else { withAnimation(.easeInOut(duration: 0.28)) { page += 1 } }
            }
            .padding(.horizontal, Frame.gutter).padding(.bottom, 26)
        }
        .towerPage()
        .centreColumn()
    }
}
