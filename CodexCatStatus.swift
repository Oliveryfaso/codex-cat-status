import AppKit
import Foundation

enum CatState: String {
    case idle
    case running
    case review
}

struct StatusSnapshot {
    let state: CatState
    let activeConversation: Int
    let pendingCalls: Int
    let runningJobs: Int
    let reviewSignals: Int
    let lastChecked: Date
}

struct PendingCallSignals {
    let running: Int
    let review: Int
}

final class AnimatedCatSprite {
    private let width = 30
    private let height = 22

    private let outline = NSColor(calibratedWhite: 0.08, alpha: 1)
    private let fur = NSColor(calibratedRed: 0.92, green: 0.50, blue: 0.20, alpha: 1)
    private let furLight = NSColor(calibratedRed: 1.00, green: 0.70, blue: 0.36, alpha: 1)
    private let furDark = NSColor(calibratedRed: 0.58, green: 0.27, blue: 0.12, alpha: 1)
    private let cream = NSColor(calibratedRed: 1.00, green: 0.86, blue: 0.58, alpha: 1)
    private let eye = NSColor(calibratedRed: 0.22, green: 0.92, blue: 0.54, alpha: 1)
    private let alert = NSColor(calibratedRed: 1.00, green: 0.18, blue: 0.20, alpha: 1)
    private let sleep = NSColor(calibratedRed: 0.25, green: 0.55, blue: 1.00, alpha: 1)

    func image(state: CatState, frame: Int) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.isTemplate = false
        image.lockFocus()

        NSGraphicsContext.current?.shouldAntialias = false
        NSGraphicsContext.current?.imageInterpolation = .none
        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()

        switch state {
        case .idle:
            drawIdle(frame: frame)
        case .running:
            drawRunning(frame: frame)
        case .review:
            drawReview(frame: frame)
        }

        image.unlockFocus()
        return image
    }

    private func drawRunning(frame: Int) {
        let phase = frame % 6
        let bob = [0, -1, -1, 0, 1, 0][phase]
        let legA = phase < 3 ? 1 : -1
        let legB = -legA

        drawTail(baseX: 22, baseY: 10 + bob, phase: phase)
        drawBody(x: 8, y: 8 + bob)
        drawHead(x: 3, y: 5 + bob, blink: false, surprised: false)

        rect(11 + legA, 17 + bob, 3, 2, outline)
        rect(12 + legA, 16 + bob, 2, 2, furDark)
        rect(20 + legB, 17 + bob, 3, 2, outline)
        rect(21 + legB, 16 + bob, 2, 2, furDark)

        rect(14, 10 + bob, 2, 1, furLight)
        rect(18, 10 + bob, 2, 1, furLight)
    }

    private func drawIdle(frame: Int) {
        let breathe = (frame / 4).isMultiple(of: 2) ? 0 : 1

        rect(8, 11, 15, 7 + breathe, outline)
        rect(9, 10, 13, 8 + breathe, outline)
        rect(10, 11, 11, 6 + breathe, fur)
        rect(12, 12, 7, 4 + breathe, furLight)
        rect(14, 14, 3, 2, cream)

        rect(4, 8, 9, 8, outline)
        rect(5, 9, 7, 6, fur)
        rect(5, 7, 2, 3, outline)
        rect(10, 7, 2, 3, outline)
        rect(6, 10, 5, 3, furLight)
        rect(7, 11, 1, 1, outline)
        rect(10, 11, 1, 1, outline)

        rect(20, 13, 5, 3, outline)
        rect(21, 14, 4, 1, furDark)
        rect(18, 15, 4, 2, outline)
        rect(18, 15, 3, 1, fur)

        if (frame / 5).isMultiple(of: 2) {
            rect(23, 4, 2, 1, sleep)
            rect(24, 3, 2, 1, sleep)
            rect(23, 2, 3, 1, sleep)
        } else {
            rect(24, 3, 2, 1, sleep)
            rect(25, 2, 2, 1, sleep)
            rect(24, 1, 3, 1, sleep)
        }
    }

    private func drawReview(frame: Int) {
        let shake = frame.isMultiple(of: 2) ? -1 : 1

        drawBody(x: 9 + shake, y: 9)
        drawHead(x: 4 + shake, y: 4, blink: false, surprised: true)
        drawTail(baseX: 22 + shake, baseY: 11, phase: 2)

        rect(25, 3, 2, 9, alert)
        rect(25, 14, 2, 2, alert)
        rect(14 + shake, 17, 3, 2, outline)
        rect(20 + shake, 17, 3, 2, outline)
    }

    private func drawHead(x: Int, y: Int, blink: Bool, surprised: Bool) {
        rect(x + 1, y + 2, 9, 8, outline)
        rect(x + 2, y + 3, 7, 6, fur)
        rect(x + 2, y + 1, 2, 3, outline)
        rect(x + 7, y + 1, 2, 3, outline)
        rect(x + 3, y + 4, 5, 2, furLight)
        rect(x + 5, y + 6, 1, 1, cream)

        if blink {
            rect(x + 3, y + 5, 2, 1, outline)
            rect(x + 7, y + 5, 2, 1, outline)
        } else if surprised {
            rect(x + 3, y + 5, 2, 2, eye)
            rect(x + 7, y + 5, 2, 2, eye)
            rect(x + 5, y + 8, 2, 2, alert)
        } else {
            rect(x + 3, y + 5, 1, 2, eye)
            rect(x + 7, y + 5, 1, 2, eye)
            rect(x + 5, y + 8, 2, 1, outline)
        }
    }

    private func drawBody(x: Int, y: Int) {
        rect(x + 1, y + 1, 15, 7, outline)
        rect(x, y + 3, 17, 4, outline)
        rect(x + 2, y + 2, 13, 5, fur)
        rect(x + 5, y + 3, 6, 3, furLight)
        rect(x + 3, y + 2, 2, 1, cream)
        rect(x + 12, y + 2, 2, 1, furDark)
    }

    private func drawTail(baseX: Int, baseY: Int, phase: Int) {
        let lift = phase.isMultiple(of: 2) ? 0 : -1
        rect(baseX, baseY + 2 + lift, 5, 2, outline)
        rect(baseX + 3, baseY + lift, 2, 4, outline)
        rect(baseX + 1, baseY + 3 + lift, 4, 1, furDark)
        rect(baseX + 4, baseY + 1 + lift, 1, 3, fur)
    }

    private func rect(_ x: Int, _ yFromTop: Int, _ w: Int, _ h: Int, _ color: NSColor) {
        color.setFill()
        NSRect(
            x: CGFloat(x),
            y: CGFloat(height - yFromTop - h),
            width: CGFloat(w),
            height: CGFloat(h)
        ).fill()
    }
}

final class CodexStatusProbe {
    private let fileManager = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser
    private let sessionScanWindow: TimeInterval = 24 * 60 * 60
    private let maxConversationTurnWindow: TimeInterval = 2 * 60 * 60

    func snapshot() -> StatusSnapshot {
        let activeConversation = countActiveConversation()
        let pendingCalls = countPendingSessionCalls()
        let runningJobs = countRunningJobs()
        let reviewSignals = countReviewSignals() + pendingCalls.review

        let state: CatState
        if reviewSignals > 0 {
            state = .review
        } else if activeConversation > 0 || pendingCalls.running > 0 || runningJobs > 0 {
            state = .running
        } else {
            state = .idle
        }

        return StatusSnapshot(
            state: state,
            activeConversation: activeConversation,
            pendingCalls: pendingCalls.running,
            runningJobs: runningJobs,
            reviewSignals: reviewSignals,
            lastChecked: Date()
        )
    }

    private func countActiveConversation() -> Int {
        guard let latestSession = latestSessionURL(),
              let text = readTail(url: latestSession, maxBytes: 600_000)
        else {
            return 0
        }

        var latestStartedTurn: String?
        var latestStartedAt: Date?
        var completedTurns = Set<String>()

        for line in text.split(separator: "\n") {
            guard let data = String(line).data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let timestamp = parseTimestamp(json["timestamp"] as? String),
                  let outerType = json["type"] as? String,
                  outerType == "event_msg",
                  let payload = json["payload"] as? [String: Any],
                  let eventType = payload["type"] as? String
            else {
                continue
            }

            if eventType == "task_started", let turnId = payload["turn_id"] as? String {
                latestStartedTurn = turnId
                latestStartedAt = timestamp
            } else if eventType == "task_complete", let turnId = payload["turn_id"] as? String {
                completedTurns.insert(turnId)
            }
        }

        guard let latestStartedTurn,
              let latestStartedAt,
              !completedTurns.contains(latestStartedTurn)
        else {
            return 0
        }

        return Date().timeIntervalSince(latestStartedAt) <= maxConversationTurnWindow ? 1 : 0
    }

    private func latestSessionURL() -> URL? {
        let sessionsDir = home.appendingPathComponent(".codex/sessions")
        guard let enumerator = fileManager.enumerator(
            at: sessionsDir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        let cutoff = Date().addingTimeInterval(-sessionScanWindow)
        var latestSession: URL?
        var latestModified = Date.distantPast

        for case let url as URL in enumerator {
            guard url.pathExtension == "jsonl" else { continue }
            guard
                let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
                let modified = values.contentModificationDate,
                modified >= cutoff,
                modified > latestModified
            else {
                continue
            }

            latestSession = url
            latestModified = modified
        }

        return latestSession
    }

    private func countPendingSessionCalls() -> PendingCallSignals {
        guard let latestSession = latestSessionURL(),
              let text = readTail(url: latestSession, maxBytes: 600_000)
        else {
            return PendingCallSignals(running: 0, review: 0)
        }

        var pending: [String: Bool] = [:]

        for line in text.split(separator: "\n") {
            guard let data = String(line).data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let payload = json["payload"] as? [String: Any],
                  let itemType = payload["type"] as? String
            else {
                continue
            }

            if itemType == "function_call" || itemType == "custom_tool_call" {
                guard let callId = payload["call_id"] as? String else { continue }
                let name = payload["name"] as? String ?? ""
                let arguments = payload["arguments"] as? String
                pending[callId] = name == "exec_command" && isEscalatedExecArguments(arguments)
            } else if itemType == "function_call_output" || itemType == "custom_tool_call_output" {
                if let callId = payload["call_id"] as? String {
                    pending.removeValue(forKey: callId)
                }
            }
        }

        let running = pending.values.filter { !$0 }.count
        let review = pending.values.filter { $0 }.count
        return PendingCallSignals(running: running, review: review)
    }

    private func isEscalatedExecArguments(_ arguments: String?) -> Bool {
        guard let arguments,
              let data = arguments.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return false
        }

        return json["sandbox_permissions"] as? String == "require_escalated"
    }

    private func parseTimestamp(_ value: String?) -> Date? {
        guard let value else { return nil }

        let isoWithFraction = ISO8601DateFormatter()
        isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoWithFraction.date(from: value) {
            return date
        }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: value)
    }

    private func readTail(url: URL, maxBytes: UInt64) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer {
            try? handle.close()
        }

        let size = (try? handle.seekToEnd()) ?? 0
        let offset = size > maxBytes ? size - maxBytes : 0
        try? handle.seek(toOffset: offset)
        let data = handle.readDataToEndOfFile()
        var text = String(data: data, encoding: .utf8) ?? ""

        if offset > 0, let firstNewline = text.firstIndex(of: "\n") {
            text = String(text[text.index(after: firstNewline)...])
        }

        return text
    }

    private func countRunningJobs() -> Int {
        let stateDb = home.appendingPathComponent(".codex/sqlite/state_5.sqlite").path
        let appDb = home.appendingPathComponent(".codex/sqlite/codex-dev.db").path

        let activeStatuses = "'running','in_progress','started','processing'"
        let jobCount = sqliteInt(
            db: stateDb,
            sql: "select count(*) from agent_jobs where lower(status) in (\(activeStatuses));"
        )
        let itemCount = sqliteInt(
            db: stateDb,
            sql: "select count(*) from agent_job_items where lower(status) in (\(activeStatuses));"
        )
        let automationCount = sqliteInt(
            db: appDb,
            sql: "select count(*) from automation_runs where lower(status) in (\(activeStatuses));"
        )

        return jobCount + itemCount + automationCount
    }

    private func countReviewSignals() -> Int {
        let stateDb = home.appendingPathComponent(".codex/sqlite/state_5.sqlite").path
        let appDb = home.appendingPathComponent(".codex/sqlite/codex-dev.db").path

        let reviewStatuses = "'needs_review','needs_approval','requires_approval'"
        let recentOnly = " and (updated_at >= cast(strftime('%s','now') as integer) - 7200 or updated_at >= (cast(strftime('%s','now') as integer) - 7200) * 1000)"
        let jobCount = sqliteInt(
            db: stateDb,
            sql: "select count(*) from agent_jobs where lower(status) in (\(reviewStatuses))\(recentOnly);"
        )
        let itemCount = sqliteInt(
            db: stateDb,
            sql: "select count(*) from agent_job_items where lower(status) in (\(reviewStatuses))\(recentOnly);"
        )
        let automationCount = sqliteInt(
            db: appDb,
            sql: "select count(*) from automation_runs where lower(status) in (\(reviewStatuses))\(recentOnly);"
        )

        return jobCount + itemCount + automationCount
    }

    private func sqliteInt(db: String, sql: String) -> Int {
        guard fileManager.fileExists(atPath: db) else { return 0 }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = [db, sql]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return 0
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return Int(output) ?? 0
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: 34)
    private let probe = CodexStatusProbe()
    private let icon = AnimatedCatSprite()
    private var timer: Timer?
    private var frame = 0
    private var statusMenuItem = NSMenuItem()
    private var detailMenuItem = NSMenuItem()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMenu()
        updateStatus()
        appendLog("launched")

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }

    private func configureMenu() {
        let menu = NSMenu()

        statusMenuItem = NSMenuItem(title: "Codex: checking", action: nil, keyEquivalent: "")
        detailMenuItem = NSMenuItem(title: "Reading ~/.codex status", action: nil, keyEquivalent: "")
        menu.addItem(statusMenuItem)
        menu.addItem(detailMenuItem)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Codex Cat", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        statusItem.button?.title = ""
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.imageScaling = .scaleProportionallyUpOrDown
    }

    private func updateStatus() {
        let snapshot = probe.snapshot()
        frame += 1
        statusItem.button?.image = icon.image(state: snapshot.state, frame: frame)
        statusItem.button?.toolTip = "Codex is \(snapshot.state.rawValue)"
        statusMenuItem.title = "Codex: \(snapshot.state.rawValue)"
        if frame.isMultiple(of: 10) {
            appendLog("state=\(snapshot.state.rawValue) conversation=\(snapshot.activeConversation) pending=\(snapshot.pendingCalls) jobs=\(snapshot.runningJobs) review=\(snapshot.reviewSignals)")
        }

        let time = DateFormatter.localizedString(
            from: snapshot.lastChecked,
            dateStyle: .none,
            timeStyle: .medium
        )
        detailMenuItem.title = "conversation \(snapshot.activeConversation), pending \(snapshot.pendingCalls), jobs \(snapshot.runningJobs), review \(snapshot.reviewSignals), \(time)"
    }

    @objc private func quit() {
        appendLog("quit")
        NSApplication.shared.terminate(nil)
    }

    private func appendLog(_ line: String) {
        let stamp = ISO8601DateFormatter().string(from: Date())
        let message = "\(stamp) \(line)\n"
        let url = URL(fileURLWithPath: "/tmp/codex-cat-status.log")

        if let data = message.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: url.path),
               let handle = try? FileHandle(forWritingTo: url) {
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
                try? handle.close()
            } else {
                try? data.write(to: url)
            }
        }
    }
}

if CommandLine.arguments.contains("--once") {
    let snapshot = CodexStatusProbe().snapshot()
    print("state=\(snapshot.state.rawValue) conversation=\(snapshot.activeConversation) pending=\(snapshot.pendingCalls) jobs=\(snapshot.runningJobs) review=\(snapshot.reviewSignals)")
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
