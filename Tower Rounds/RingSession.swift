import SwiftUI

enum RingStage: Int {
    case standing = 0
    case ringing
    case stood
}

struct BlowMark: Identifiable {
    let id: Int
    let rowIndex: Int
    let place: Int
    let errorMs: Double
    let clean: Bool
}

final class RingSession: ObservableObject {
    @Published var stage: RingStage = .standing
    @Published var rowIndex: Int = 0
    @Published var beat: Double = 0
    @Published var wheelAngle: Double = 0
    @Published var pull: Double = 0
    @Published var handstroke: Bool = true
    @Published var marks: [BlowMark] = []
    @Published var lastError: Double? = nil
    @Published var note: String? = nil
    @Published var strikingFlash: Double = 0
    @Published var otherFlash: [Int: Double] = [:]

    let method: RingingMethod
    let myBell: Int
    let isDaily: Bool
    let run: RowRun
    let voices: [BellVoice]
    let targetChanges: Int

    var blowInterval: Double = 0.30
    private var lastTick = Date()
    private var struckThisRow = false
    private var nextBlowIndex = 0

    init(method: RingingMethod, bell: Int, isDaily: Bool) {
        self.method = method
        self.myBell = bell
        self.isDaily = isDaily
        run = generateRows(method, leads: 12)
        voices = Ring.voices(for: method.bells)
        targetChanges = max(4, run.rows.count - 1)
        blowInterval = 0.34 - Double(method.bells) * 0.012
    }

    var totalBlows: Int { run.rows.count * method.bells }

    var myPlace: Int {
        guard rowIndex < run.rows.count else { return 1 }
        return (run.rows[rowIndex].firstIndex(of: myBell) ?? 0) + 1
    }

    var nextPlace: Int {
        let r = min(run.rows.count - 1, rowIndex + 1)
        return (run.rows[r].firstIndex(of: myBell) ?? 0) + 1
    }

    var accuracy: Int {
        guard !marks.isEmpty else { return 0 }
        let clean = marks.filter { $0.clean }.count
        let mean = marks.map { abs($0.errorMs) }.reduce(0, +) / Double(marks.count)
        let ratio = Double(clean) / Double(marks.count)
        let tightness = max(0.0, 1.0 - mean / 140.0)
        return max(0, min(100, Int(ratio * 62 + tightness * 38)))
    }

    var changesRung: Int { max(0, rowIndex) }

    func start() {
        stage = .ringing
        rowIndex = 0
        beat = 0
        nextBlowIndex = 0
        lastTick = Date()
        marks.removeAll()
        note = "Rounds first. Wait for your place."
    }

    func tick(_ now: Date) {
        guard stage == .ringing else { return }
        let dt = min(0.08, now.timeIntervalSince(lastTick))
        lastTick = now
        beat += dt / blowInterval
        wheelAngle += dt * 2.4
        if strikingFlash > 0 { strikingFlash = max(0, strikingFlash - dt * 3.0) }
        var updated: [Int: Double] = [:]
        for (k, v) in otherFlash where v > 0 { updated[k] = max(0, v - dt * 3.0) }
        otherFlash = updated

        while beat >= 1.0 {
            beat -= 1.0
            advanceBlow()
        }
    }

    private func advanceBlow() {
        let place = nextBlowIndex % method.bells
        if place == 0 && nextBlowIndex > 0 {
            if !struckThisRow {
                marks.append(BlowMark(id: marks.count, rowIndex: rowIndex,
                                      place: myPlace, errorMs: 400, clean: false))
                note = "Missed a blow. Keep pulling — a bell that stops is worse than a bell that is late."
            }
            struckThisRow = false
            rowIndex += 1
            handstroke.toggle()
            if rowIndex >= min(run.rows.count - 1, targetChanges) {
                stage = .stood
                return
            }
        }
        let bellHere = run.rows[min(rowIndex, run.rows.count - 1)][place]
        if bellHere != myBell {
            otherFlash[bellHere] = 1.0
        }
        nextBlowIndex += 1
    }

    var expectedFraction: Double {
        Double(myPlace - 1)
    }

    var currentFraction: Double {
        Double((nextBlowIndex % method.bells)) + beat
    }

    func strikeNow(store: TowerStore) {
        guard stage == .ringing, !struckThisRow else { return }
        let errorBlows = currentFraction - expectedFraction
        let errorMs = errorBlows * blowInterval * 1000.0
        let clean = abs(errorMs) < 62
        struckThisRow = true
        strikingFlash = 1.0
        marks.append(BlowMark(id: marks.count, rowIndex: rowIndex, place: myPlace,
                              errorMs: errorMs, clean: clean))
        store.noteBlow(clean: clean)
        lastError = errorMs
        if clean {
            Strike.tap()
            note = nil
        } else if errorMs < 0 {
            Strike.firm()
            note = "Early by \(Int(-errorMs)) ms. You are cutting the bell in front."
        } else {
            Strike.firm()
            note = "Late by \(Int(errorMs)) ms. There is a hole before your blow."
        }
        pull = 1.0
        withAnimation(.easeOut(duration: 0.35)) { pull = 0 }
    }
}
