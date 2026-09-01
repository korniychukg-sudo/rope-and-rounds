import SwiftUI
import Combine

struct PealBoard: Codable, Identifiable {
    var id: String
    var methodID: String
    var changes: Int
    var accuracy: Int
    var dayIndex: Int
    var minutes: Int
    var bellRung: Int

    var method: RingingMethod? { MethodBook.method(methodID) }

    var gradeName: String {
        switch accuracy {
        case 92...: return "Struck like a clock"
        case 80..<92: return "Good striking"
        case 64..<80: return "Passable"
        case 46..<64: return "Rough"
        default: return "A fire in a brass foundry"
        }
    }
}

struct TowerRank {
    let title: String
    let threshold: Int
    let note: String
}

enum TowerRanks {
    static let ladder: [TowerRank] = [
        TowerRank(title: "Learner", threshold: 0,
                  note: "You can handle a rope and pull off at the right moment. That took most people three months."),
        TowerRank(title: "Rounds Ringer", threshold: 300,
                  note: "You can hold your place in rounds and call changes without losing the rhythm."),
        TowerRank(title: "Method Ringer", threshold: 880,
                  note: "Plain Bob and Grandsire are safe. You count places instead of following ropes."),
        TowerRank(title: "Surprise Ringer", threshold: 1900,
                  note: "Cambridge and beyond. You know the line, the place bells and where you go wrong."),
        TowerRank(title: "Conductor", threshold: 3300,
                  note: "You can hear who is out of place and put them right without stopping the ringing.")
    ]

    static func rank(for points: Int) -> TowerRank {
        var found = ladder[0]
        for r in ladder where points >= r.threshold { found = r }
        return found
    }

    static func next(after points: Int) -> TowerRank? { ladder.first(where: { $0.threshold > points }) }
}

struct TowerSnapshot: Codable {
    var boards: [PealBoard]?
    var bestByMethod: [String: Int]?
    var points: Int?
    var streak: Int?
    var bestStreak: Int?
    var lastDailyDay: Int?
    var dailyDone: [Int]?
    var blowsStruck: Int?
    var blowsClean: Int?
    var changesRung: Int?
    var onboarded: Bool?
}

final class TowerStore: ObservableObject {
    @Published var boards: [PealBoard] = []
    @Published var bestByMethod: [String: Int] = [:]
    @Published var points: Int = 0
    @Published var streak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var lastDailyDay: Int = -1
    @Published var dailyDone: [Int] = []
    @Published var blowsStruck: Int = 0
    @Published var blowsClean: Int = 0
    @Published var changesRung: Int = 0
    @Published var onboarded: Bool = false

    private let key = "tower-rounds-store-v1"
    private var dirty = false

    static let epoch: TimeInterval = 1_767_225_600
    static var todayIndex: Int { Int(floor((Date().timeIntervalSince1970 - epoch) / 86_400.0)) }

    init() { load() }

    var rank: TowerRank { TowerRanks.rank(for: points) }
    var nextRank: TowerRank? { TowerRanks.next(after: points) }

    var rankProgress: Double {
        let cur = rank.threshold
        guard let n = nextRank else { return 1 }
        let span = Double(n.threshold - cur)
        guard span > 0 else { return 1 }
        return min(1, max(0, Double(points - cur) / span))
    }

    var liveStreak: Int {
        let t = TowerStore.todayIndex
        if lastDailyDay == t || lastDailyDay == t - 1 { return streak }
        return 0
    }

    var striking: Double {
        guard blowsStruck > 0 else { return 0 }
        return Double(blowsClean) / Double(blowsStruck)
    }

    func best(for id: String) -> Int? { bestByMethod[id] }

    func boardFor(_ id: String) -> PealBoard? {
        boards.filter { $0.methodID == id }.max(by: { $0.accuracy < $1.accuracy })
    }

    func dailyIsDone(_ day: Int) -> Bool { dailyDone.contains(day) }

    @discardableResult
    func record(method: RingingMethod, changes: Int, accuracy: Int,
                minutes: Int, bell: Int) -> PealBoard {
        let b = PealBoard(id: "b\(boards.count)-\(TowerStore.todayIndex)-\(method.id)",
                          methodID: method.id, changes: changes, accuracy: accuracy,
                          dayIndex: TowerStore.todayIndex, minutes: minutes, bellRung: bell)
        changesRung += changes
        let prev = bestByMethod[method.id] ?? -1
        if accuracy > prev {
            bestByMethod[method.id] = accuracy
            points += prev < 0 ? 60 + accuracy / 2 : max(5, accuracy - prev)
            boards.removeAll { $0.methodID == method.id }
            boards.insert(b, at: 0)
        } else {
            points += 8
        }
        if boards.count > 40 { boards.removeLast(boards.count - 40) }
        dirty = true
        saveSoon()
        return b
    }

    func noteBlow(clean: Bool) {
        blowsStruck += 1
        if clean { blowsClean += 1 }
        dirty = true
    }

    func noteDaily(day: Int, accuracy: Int) {
        guard !dailyIsDone(day) else { return }
        dailyDone.append(day)
        if dailyDone.count > 400 { dailyDone.removeFirst(dailyDone.count - 400) }
        if lastDailyDay == day - 1 { streak += 1 } else if lastDailyDay != day { streak = 1 }
        lastDailyDay = day
        bestStreak = max(bestStreak, streak)
        points += 30 + accuracy / 2
        dirty = true
        saveSoon()
    }

    func markOnboarded() { onboarded = true; dirty = true; saveNow() }

    private func saveSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.saveNow() }
    }

    func saveNow() {
        guard dirty else { return }
        let snap = TowerSnapshot(boards: boards, bestByMethod: bestByMethod, points: points,
                                 streak: streak, bestStreak: bestStreak,
                                 lastDailyDay: lastDailyDay, dailyDone: dailyDone,
                                 blowsStruck: blowsStruck, blowsClean: blowsClean,
                                 changesRung: changesRung, onboarded: onboarded)
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: key)
            dirty = false
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let snap = try? JSONDecoder().decode(TowerSnapshot.self, from: data) else { return }
        boards = snap.boards ?? []
        bestByMethod = snap.bestByMethod ?? [:]
        points = snap.points ?? 0
        streak = snap.streak ?? 0
        bestStreak = snap.bestStreak ?? 0
        lastDailyDay = snap.lastDailyDay ?? -1
        dailyDone = snap.dailyDone ?? []
        blowsStruck = snap.blowsStruck ?? 0
        blowsClean = snap.blowsClean ?? 0
        changesRung = snap.changesRung ?? 0
        onboarded = snap.onboarded ?? false
    }
}
