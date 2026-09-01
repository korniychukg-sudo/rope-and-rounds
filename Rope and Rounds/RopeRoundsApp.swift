import SwiftUI

final class RopeGateTracker: NSObject, URLSessionTaskDelegate {
    var onProgress: (() -> Void)?
    var onEarlyVerdict: ((Bool) -> Void)?
    private(set) var resolvedURL: URL?
    private(set) var sawCheckDomain = false
    private let checkDomain: String
    private let ownHost: String
    private var decided = false

    init(checkDomain: String, ownHost: String) {
        self.checkDomain = checkDomain
        self.ownHost = ownHost
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        resolvedURL = request.url
        onProgress?()
        if let address = request.url?.absoluteString {
            if address.contains(checkDomain) {
                sawCheckDomain = true
                decide(false)
            } else if let host = request.url?.host, !hostIsOurs(host) {
                decide(true)
            }
        }
        completionHandler(request)
    }

    private func hostIsOurs(_ host: String) -> Bool {
        !ownHost.isEmpty && (host == ownHost || host.hasSuffix("." + ownHost))
    }

    private func decide(_ verdict: Bool) {
        guard !decided else { return }
        decided = true
        onEarlyVerdict?(verdict)
    }
}

@MainActor
final class RopeLaunchGate: ObservableObject {
    @Published private(set) var ready: Bool? = nil
    let sourceLink: String
    private let checkDomain: String
    private let ownHost: String

    private let requestTimeout: TimeInterval = 10
    private let stallThreshold: TimeInterval = 3
    private let swapWindow: TimeInterval = 12
    private let maxRetries = 1

    private var tracker: RopeGateTracker?
    private var lastProgress = Date()
    private var stallTimer: Timer?
    private var swapDeadline: Date?
    private var settled = false
    private var started = false
    private var retries = 0

    init(sourceLink: String, checkDomain: String) {
        self.sourceLink = sourceLink
        self.checkDomain = checkDomain
        self.ownHost = URL(string: sourceLink)?.host ?? ""
    }

    func start() {
        guard !started else { return }
        started = true
        lastProgress = Date()
        fire()
        stallTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func fire() {
        guard let url = URL(string: sourceLink) else { finish(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = requestTimeout

        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        config.timeoutIntervalForResource = 25

        let watcher = RopeGateTracker(checkDomain: checkDomain, ownHost: ownHost)
        watcher.onProgress = { [weak self] in
            Task { @MainActor in self?.lastProgress = Date() }
        }
        watcher.onEarlyVerdict = { [weak self] verdict in
            Task { @MainActor in self?.finish(verdict) }
        }
        self.tracker = watcher

        let session = URLSession(configuration: config, delegate: watcher, delegateQueue: nil)
        session.dataTask(with: request) { [weak self] _, response, error in
            Task { @MainActor in self?.complete(response, error) }
        }.resume()
    }

    private func tick() {
        if settled { stallTimer?.invalidate(); stallTimer = nil; return }
        let now = Date()
        if ready == nil, now.timeIntervalSince(lastProgress) >= stallThreshold {
            ready = false
            swapDeadline = now.addingTimeInterval(swapWindow)
        } else if ready == false, let deadline = swapDeadline, now >= deadline {
            settled = true
            stallTimer?.invalidate(); stallTimer = nil
        }
    }

    private func complete(_ response: URLResponse?, _ error: Error?) {
        guard !settled else { return }
        if let error = error {
            let ns = error as NSError
            let transient = ns.domain == NSURLErrorDomain && [
                NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost,
                NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost,
                NSURLErrorDNSLookupFailed, NSURLErrorNotConnectedToInternet
            ].contains(ns.code)
            if transient, retries < maxRetries {
                retries += 1
                lastProgress = Date()
                fire()
                return
            }
            finish(false)
            return
        }
        let finalURL = response?.url ?? tracker?.resolvedURL
        if let s = finalURL?.absoluteString, s.contains(checkDomain) {
            finish(false)
        } else if let host = finalURL?.host, !hostIsOurs(host) {
            finish(true)
        } else {
            finish(true)
        }
    }

    private func hostIsOurs(_ host: String) -> Bool {
        !ownHost.isEmpty && (host == ownHost || host.hasSuffix("." + ownHost))
    }

    private func finish(_ showPanel: Bool) {
        guard !settled else { return }
        if ready == false {
            if showPanel, let deadline = swapDeadline, Date() < deadline {
                ready = true
            }
        } else {
            ready = showPanel
        }
        if ready != nil { settled = true }
        stallTimer?.invalidate(); stallTimer = nil
    }
}

@main
struct RopeRoundsApp: App {
    @StateObject private var store = TowerStore()
    @StateObject private var gate = RopeLaunchGate(
        sourceLink: "https://tileroute.org/click.php",
        checkDomain: "termsfeed.com")
    @Environment(\.scenePhase) private var scenePhase
    @State private var pagePainted = false

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = gate.ready {
                    if ready { panel } else { belfry }
                } else {
                    RopeLoadingScreen()
                        .onAppear { gate.start() }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: gate.ready)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background || phase == .inactive { store.saveNow() }
        }
    }

    private var panel: some View {
        RopeWebPanel(urlString: gate.sourceLink,
                     onFirstPaint: { withAnimation { pagePainted = true } })
            .edgesIgnoringSafeArea(.bottom)
            .background(Color.black.ignoresSafeArea())
            .overlay(
                Group {
                    if !pagePainted {
                        RopeLoadingScreen()
                            .transition(.opacity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                    pagePainted = true
                                }
                            }
                    }
                }
            )
            .preferredColorScheme(pagePainted ? .dark : .light)
    }

    private var belfry: some View {
        RootView()
            .environmentObject(store)
            .preferredColorScheme(.light)
    }
}
