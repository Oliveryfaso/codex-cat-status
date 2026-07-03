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
    let tokenUsage: TokenUsageSnapshot
    let lastChecked: Date
}

struct PendingCallSignals {
    let running: Int
    let review: Int
}

struct SessionScanSignals {
    let activeConversation: Int
    let pendingCalls: PendingCallSignals
    let tokenUsage: TokenUsageSnapshot
}

struct PendingCallRecord {
    let review: Bool
    let turnID: String?
}

struct TokenUsageRecord {
    let date: Date
    let totalTokens: Int
}

struct TokenBucketSnapshot {
    let usedPercent: Double
    let windowMinutes: Int
    let resetsAt: Date?

    var remainingPercent: Double {
        max(0, 100 - usedPercent)
    }
}

struct TokenUsageSnapshot {
    let contextWindow: Int?
    let currentInputTokens: Int?
    let currentOutputTokens: Int?
    let currentTotalTokens: Int?
    let totalSessionTokens: Int?
    let observedTodayTokens: Int
    let observedWeekTokens: Int
    let primaryLimit: TokenBucketSnapshot?
    let secondaryLimit: TokenBucketSnapshot?
    let lastUpdated: Date?

    static let empty = TokenUsageSnapshot(
        contextWindow: nil,
        currentInputTokens: nil,
        currentOutputTokens: nil,
        currentTotalTokens: nil,
        totalSessionTokens: nil,
        observedTodayTokens: 0,
        observedWeekTokens: 0,
        primaryLimit: nil,
        secondaryLimit: nil,
        lastUpdated: nil
    )

    var remainingContextTokens: Int? {
        guard let contextWindow, let currentInputTokens else { return nil }
        return max(0, contextWindow - currentInputTokens)
    }

    var remainingContextPercent: Double? {
        guard let contextWindow, contextWindow > 0, let remainingContextTokens else { return nil }
        return min(100, max(0, Double(remainingContextTokens) / Double(contextWindow) * 100))
    }

    var menuBarText: String {
        guard let remainingContextPercent else { return "[------] --" }
        return formatBattery(remainingContextPercent, width: 6, includePercent: true)
    }
}

struct SessionActivityState {
    var offset: UInt64 = 0
    var partialLine = ""
    var latestStartedTurn: String?
    var latestStartedAt: Date?
    var completedTurns = Set<String>()
    var pending: [String: PendingCallRecord] = [:]
    var tokenEvents: [TokenUsageRecord] = []
    var latestTokenUsage: TokenUsageSnapshot = .empty
}

func formatCompact(_ value: Int) -> String {
    let number = Double(value)
    if value >= 1_000_000 {
        return String(format: "%.1fM", number / 1_000_000)
    }
    if value >= 10_000 {
        return "\(Int(number / 1_000))k"
    }
    if value >= 1_000 {
        return String(format: "%.1fk", number / 1_000)
    }
    return "\(value)"
}

func formatPercent(_ value: Double) -> String {
    if value >= 10 {
        return "\(Int(value.rounded()))%"
    }
    return String(format: "%.1f%%", value)
}

func formatBattery(_ percent: Double?, width: Int = 10, includePercent: Bool = true) -> String {
    guard let percent else {
        return "[\(String(repeating: "-", count: width))]" + (includePercent ? " --" : "")
    }

    let clamped = min(100, max(0, percent))
    var filled = Int((clamped / 100 * Double(width)).rounded())
    if clamped > 0, filled == 0 {
        filled = 1
    }
    filled = min(width, max(0, filled))

    let empty = width - filled
    let bar = "[\(String(repeating: "#", count: filled))\(String(repeating: "-", count: empty))]"
    return includePercent ? "\(bar) \(formatPercent(clamped))" : bar
}

func formatTokenBucket(_ bucket: TokenBucketSnapshot?) -> String {
    guard let bucket else { return "unknown" }

    let hours = Double(bucket.windowMinutes) / 60
    let window = bucket.windowMinutes >= 1440
        ? "\(bucket.windowMinutes / 1440)d"
        : String(format: "%.0fh", hours)
    let reset: String
    if let resetsAt = bucket.resetsAt {
        reset = DateFormatter.localizedString(from: resetsAt, dateStyle: .none, timeStyle: .short)
    } else {
        reset = "unknown"
    }

    return "\(formatBattery(bucket.remainingPercent)) left in \(window), resets \(reset)"
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
        let phase = frame % 8
        let bob = [1, 0, -1, -2, -1, 0, 1, 0][phase]
        let lean = [0, 1, 1, 0, -1, -1, 0, 1][phase]
        let frontLeg = [2, 1, 0, -1, -2, -1, 0, 1][phase]
        let backLeg = [-2, -1, 0, 1, 2, 1, 0, -1][phase]
        let frontFootDrop = [1, 0, 0, 0, 1, 1, 0, 0][phase]
        let backFootDrop = [0, 1, 1, 0, 0, 0, 1, 1][phase]

        drawTail(baseX: 22 + lean, baseY: 10 + bob, phase: phase)
        drawBody(x: 8 + lean, y: 8 + bob)
        drawHead(x: 3 + lean, y: 5 + bob, blink: false, surprised: false)

        rect(11 + lean + frontLeg, 17 + bob + frontFootDrop, 3, 2, outline)
        rect(12 + lean + frontLeg, 16 + bob + frontFootDrop, 2, 2, furDark)
        rect(20 + lean + backLeg, 17 + bob + backFootDrop, 3, 2, outline)
        rect(21 + lean + backLeg, 16 + bob + backFootDrop, 2, 2, furDark)

        rect(14 + lean, 10 + bob, 2, 1, furLight)
        rect(18 + lean, 10 + bob, 2, 1, furLight)
    }

    private func drawIdle(frame: Int) {
        let phase = frame % 12
        let breathe = phase < 6 ? 0 : 1
        let tailLift = [0, 0, -1, -1, 0, 1, 1, 0, 0, -1, 0, 1][phase]
        let sleepShift = phase < 6 ? 0 : 1

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

        rect(20, 13 + tailLift, 5, 3, outline)
        rect(21, 14 + tailLift, 4, 1, furDark)
        rect(18, 15 + tailLift, 4, 2, outline)
        rect(18, 15 + tailLift, 3, 1, fur)

        if phase < 6 {
            rect(23 + sleepShift, 4, 2, 1, sleep)
            rect(24 + sleepShift, 3, 2, 1, sleep)
            rect(23 + sleepShift, 2, 3, 1, sleep)
        } else {
            rect(24 + sleepShift, 3, 2, 1, sleep)
            rect(25 + sleepShift, 2, 2, 1, sleep)
            rect(24 + sleepShift, 1, 3, 1, sleep)
        }
    }

    private func drawReview(frame: Int) {
        let phase = frame % 4
        let shake = [-2, 1, 2, -1][phase]
        let bob = [0, -1, 0, 1][phase]
        let markShift = [0, 1, 0, -1][phase]

        drawBody(x: 9 + shake, y: 9 + bob)
        drawHead(x: 4 + shake, y: 4 + bob, blink: false, surprised: true)
        drawTail(baseX: 22 + shake, baseY: 11 + bob, phase: phase)

        rect(25 + markShift, 2 + bob, 2, 10, alert)
        rect(25 + markShift, 14 + bob, 2, 2, alert)
        rect(14 + shake, 17 + bob, 3, 2, outline)
        rect(20 + shake, 17 + bob, 3, 2, outline)
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
        let lift = [1, 0, -1, -2, -1, 0, 1, 0][phase % 8]
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

final class PixelStatusBadge {
    private let width = 46
    private let height = 24
    private let cat = AnimatedCatSprite()

    private let outline = NSColor(calibratedWhite: 0.08, alpha: 1)
    private let shell = NSColor(calibratedRed: 1.00, green: 0.84, blue: 0.52, alpha: 1)
    private let low = NSColor(calibratedRed: 1.00, green: 0.12, blue: 0.16, alpha: 1)
    private let mid = NSColor(calibratedRed: 1.00, green: 0.58, blue: 0.12, alpha: 1)
    private let high = NSColor(calibratedRed: 0.12, green: 0.82, blue: 0.36, alpha: 1)
    private let shine = NSColor(calibratedRed: 1.00, green: 0.95, blue: 0.74, alpha: 1)

    func image(state: CatState, frame: Int, tokenUsage: TokenUsageSnapshot) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.isTemplate = false
        image.lockFocus()

        NSGraphicsContext.current?.shouldAntialias = false
        NSGraphicsContext.current?.imageInterpolation = .none
        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()

        cat.image(state: state, frame: frame).draw(
            in: NSRect(x: 0, y: 1, width: 30, height: 22),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
        drawBattery(percent: tokenUsage.remainingContextPercent)

        image.unlockFocus()
        return image
    }

    private func drawBattery(percent: Double?) {
        let x = 34
        let y = 3
        let bodyWidth = 10
        let bodyHeight = 18
        let clamped = min(100, max(0, percent ?? 0))
        let innerHeight = bodyHeight - 4
        let fillHeight = Int((clamped / 100 * Double(innerHeight)).rounded())
        let fillColor = clamped < 20 ? low : (clamped < 45 ? mid : high)

        rect(x + 3, y - 2, 4, 2, outline)
        rect(x, y, bodyWidth, bodyHeight, outline)
        rect(x + 1, y + 1, bodyWidth - 2, bodyHeight - 2, shell)

        if fillHeight > 0 {
            let fillY = y + bodyHeight - 2 - fillHeight
            rect(x + 2, fillY, bodyWidth - 4, fillHeight, fillColor)
            rect(x + 3, fillY, 1, max(1, fillHeight - 1), shine.withAlphaComponent(0.42))
        }

        for tick in stride(from: y + 6, through: y + bodyHeight - 6, by: 5) {
            rect(x + 2, tick, bodyWidth - 4, 1, outline.withAlphaComponent(0.22))
        }
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
    private let maxConversationTurnWindow: TimeInterval = 12 * 60 * 60
    private let maxSessionFiles = 30
    private let sessionTailBytes: UInt64 = 8_000_000
    private var sessionStates: [String: SessionActivityState] = [:]

    func snapshot() -> StatusSnapshot {
        let sessionSignals = scanRecentSessions()
        let runningJobs = countRunningJobs()
        let reviewSignals = countReviewSignals() + sessionSignals.pendingCalls.review

        let state: CatState
        if reviewSignals > 0 {
            state = .review
        } else if sessionSignals.activeConversation > 0 || sessionSignals.pendingCalls.running > 0 || runningJobs > 0 {
            state = .running
        } else {
            state = .idle
        }

        return StatusSnapshot(
            state: state,
            activeConversation: sessionSignals.activeConversation,
            pendingCalls: sessionSignals.pendingCalls.running,
            runningJobs: runningJobs,
            reviewSignals: reviewSignals,
            tokenUsage: sessionSignals.tokenUsage,
            lastChecked: Date()
        )
    }

    private func scanRecentSessions() -> SessionScanSignals {
        var activeConversation = 0
        var pendingRunning = 0
        var pendingReview = 0
        var tokenStates: [SessionActivityState] = []
        let sessions = recentSessionURLs(limit: maxSessionFiles)
        let activeSessionPaths = Set(sessions.map(\.path))
        sessionStates = sessionStates.filter { activeSessionPaths.contains($0.key) }

        for session in sessions {
            guard let size = fileSize(url: session) else {
                continue
            }

            var state = sessionStates[session.path] ?? SessionActivityState()
            if size < state.offset {
                state = SessionActivityState()
            }

            if state.offset == 0 {
                if let text = readTail(url: session, maxBytes: sessionTailBytes) {
                    applySessionLines(text, to: &state)
                }
            } else if size > state.offset {
                if let text = readRange(url: session, from: state.offset) {
                    applySessionLines(text, to: &state)
                }
            }

            state.offset = size
            sessionStates[session.path] = state
            tokenStates.append(state)

            let signals = sessionSignals(from: state)
            guard signals.active else {
                continue
            }

            activeConversation += 1
            pendingRunning += signals.pending.running
            pendingReview += signals.pending.review
        }

        return SessionScanSignals(
            activeConversation: activeConversation,
            pendingCalls: PendingCallSignals(running: pendingRunning, review: pendingReview),
            tokenUsage: aggregateTokenUsage(from: tokenStates)
        )
    }

    private func applySessionLines(_ text: String, to state: inout SessionActivityState) {
        guard !text.isEmpty else { return }

        let combined = state.partialLine + text
        let hasTrailingNewline = combined.last == "\n"
        var lines = combined.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if hasTrailingNewline {
            state.partialLine = ""
        } else {
            state.partialLine = lines.popLast() ?? ""
        }

        for line in lines where !line.isEmpty {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let outerType = json["type"] as? String,
                  let payload = json["payload"] as? [String: Any],
                  let payloadType = payload["type"] as? String
            else {
                continue
            }

            if let metadata = payload["internal_chat_message_metadata_passthrough"] as? [String: Any],
               let observedTurnID = metadata["turn_id"] as? String,
               let observedAt = parseTimestamp(json["timestamp"] as? String),
               state.latestStartedAt == nil || observedAt > state.latestStartedAt! {
                state.latestStartedTurn = observedTurnID
                state.latestStartedAt = observedAt
            }

            if outerType == "event_msg" {
                if payloadType == "task_started", let turnID = payload["turn_id"] as? String {
                    state.latestStartedTurn = turnID
                    state.latestStartedAt = parseStartedAt(payload["started_at"]) ?? parseTimestamp(json["timestamp"] as? String)
                } else if payloadType == "task_complete", let turnID = payload["turn_id"] as? String {
                    state.completedTurns.insert(turnID)
                } else if payloadType == "token_count", let timestamp = parseTimestamp(json["timestamp"] as? String) {
                    applyTokenCount(payload: payload, timestamp: timestamp, to: &state)
                }
            } else if payloadType == "function_call" || payloadType == "custom_tool_call" {
                guard let callID = payload["call_id"] as? String else { continue }

                let name = payload["name"] as? String ?? ""
                let arguments = payload["arguments"] as? String
                let metadata = payload["internal_chat_message_metadata_passthrough"] as? [String: Any]
                let turnID = metadata?["turn_id"] as? String
                state.pending[callID] = PendingCallRecord(
                    review: name == "exec_command" && isEscalatedExecArguments(arguments),
                    turnID: turnID
                )
            } else if payloadType == "function_call_output" || payloadType == "custom_tool_call_output" {
                if let callID = payload["call_id"] as? String {
                    state.pending.removeValue(forKey: callID)
                }
            }
        }
    }

    private func applyTokenCount(payload: [String: Any], timestamp: Date, to state: inout SessionActivityState) {
        guard let info = payload["info"] as? [String: Any] else { return }

        let lastUsage = info["last_token_usage"] as? [String: Any]
        let totalUsage = info["total_token_usage"] as? [String: Any]
        let rateLimits = payload["rate_limits"] as? [String: Any]

        let lastTotal = intValue(lastUsage?["total_tokens"]) ?? 0
        if lastTotal > 0 {
            state.tokenEvents.append(TokenUsageRecord(date: timestamp, totalTokens: lastTotal))
        }

        let contextWindow = intValue(info["model_context_window"])
        let snapshot = TokenUsageSnapshot(
            contextWindow: contextWindow,
            currentInputTokens: intValue(lastUsage?["input_tokens"]),
            currentOutputTokens: intValue(lastUsage?["output_tokens"]),
            currentTotalTokens: intValue(lastUsage?["total_tokens"]),
            totalSessionTokens: intValue(totalUsage?["total_tokens"]),
            observedTodayTokens: 0,
            observedWeekTokens: 0,
            primaryLimit: parseTokenBucket(rateLimits?["primary"]),
            secondaryLimit: parseTokenBucket(rateLimits?["secondary"]),
            lastUpdated: timestamp
        )

        if state.latestTokenUsage.lastUpdated == nil || timestamp >= state.latestTokenUsage.lastUpdated! {
            state.latestTokenUsage = snapshot
        }

        let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        state.tokenEvents.removeAll { $0.date < weekAgo }
    }

    private func aggregateTokenUsage(from states: [SessionActivityState]) -> TokenUsageSnapshot {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            ?? now.addingTimeInterval(-7 * 24 * 60 * 60)

        var today = 0
        var week = 0
        var latest = TokenUsageSnapshot.empty

        for state in states {
            for event in state.tokenEvents {
                if event.date >= startOfToday {
                    today += event.totalTokens
                }
                if event.date >= startOfWeek {
                    week += event.totalTokens
                }
            }

            let candidate = state.latestTokenUsage
            if let candidateUpdated = candidate.lastUpdated,
               latest.lastUpdated == nil || candidateUpdated > latest.lastUpdated! {
                latest = candidate
            }
        }

        return TokenUsageSnapshot(
            contextWindow: latest.contextWindow,
            currentInputTokens: latest.currentInputTokens,
            currentOutputTokens: latest.currentOutputTokens,
            currentTotalTokens: latest.currentTotalTokens,
            totalSessionTokens: latest.totalSessionTokens,
            observedTodayTokens: today,
            observedWeekTokens: week,
            primaryLimit: latest.primaryLimit,
            secondaryLimit: latest.secondaryLimit,
            lastUpdated: latest.lastUpdated
        )
    }

    private func sessionSignals(from state: SessionActivityState) -> (active: Bool, pending: PendingCallSignals) {
        guard let activeTurn = state.latestStartedTurn,
              let latestStartedAt = state.latestStartedAt,
              !state.completedTurns.contains(activeTurn),
              Date().timeIntervalSince(latestStartedAt) <= maxConversationTurnWindow
        else {
            return (false, PendingCallSignals(running: 0, review: 0))
        }

        let activePending = state.pending.values.filter { record in
            record.turnID == nil || record.turnID == activeTurn
        }

        let running = activePending.filter { !$0.review }.count
        let review = activePending.filter { $0.review }.count
        return (true, PendingCallSignals(running: running, review: review))
    }

    private func recentSessionURLs(limit: Int) -> [URL] {
        let sessionsDir = home.appendingPathComponent(".codex/sessions")
        guard let enumerator = fileManager.enumerator(
            at: sessionsDir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let cutoff = Date().addingTimeInterval(-sessionScanWindow)
        var sessions: [(url: URL, modified: Date)] = []

        for case let url as URL in enumerator {
            guard url.pathExtension == "jsonl" else { continue }
            guard
                let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
                let modified = values.contentModificationDate,
                modified >= cutoff
            else {
                continue
            }

            sessions.append((url, modified))
        }

        return Array(sessions.sorted { $0.modified > $1.modified }.prefix(limit).map(\.url))
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

    private func parseStartedAt(_ value: Any?) -> Date? {
        if let number = value as? NSNumber {
            return Date(timeIntervalSince1970: number.doubleValue)
        }

        if let seconds = value as? TimeInterval {
            return Date(timeIntervalSince1970: seconds)
        }

        return nil
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

    private func readRange(url: URL, from offset: UInt64) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer {
            try? handle.close()
        }

        try? handle.seek(toOffset: offset)
        let data = handle.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func fileSize(url: URL) -> UInt64? {
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let size = values.fileSize
        else {
            return nil
        }

        return UInt64(size)
    }

    private func parseTokenBucket(_ value: Any?) -> TokenBucketSnapshot? {
        guard let value = value as? [String: Any],
              let usedPercent = doubleValue(value["used_percent"]),
              let windowMinutes = intValue(value["window_minutes"])
        else {
            return nil
        }

        let resetsAt: Date?
        if let seconds = doubleValue(value["resets_at"]) {
            resetsAt = Date(timeIntervalSince1970: seconds)
        } else {
            resetsAt = nil
        }

        return TokenBucketSnapshot(
            usedPercent: usedPercent,
            windowMinutes: windowMinutes,
            resetsAt: resetsAt
        )
    }

    private func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }
        if let value = value as? NSNumber {
            return value.intValue
        }
        if let value = value as? String {
            return Int(value)
        }
        return nil
    }

    private func doubleValue(_ value: Any?) -> Double? {
        if let value = value as? Double {
            return value
        }
        if let value = value as? NSNumber {
            return value.doubleValue
        }
        if let value = value as? String {
            return Double(value)
        }
        return nil
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

final class TokenDetailsPanel: NSView {
    var snapshot: StatusSnapshot? {
        didSet {
            needsDisplay = true
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 340, height: 282)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSGraphicsContext.current?.shouldAntialias = true
        drawPanelBackground()

        guard let snapshot else {
            drawText("Reading ~/.codex status", x: 18, y: 20, size: 12, weight: .semibold)
            return
        }

        let token = snapshot.tokenUsage
        drawText("Codex Cat Status", x: 18, y: 18, size: 14, weight: .bold)
        drawPill(snapshot.state.rawValue.uppercased(), x: 242, y: 15, color: stateColor(snapshot.state))

        drawText(
            "conv \(snapshot.activeConversation)  pending \(snapshot.pendingCalls)  jobs \(snapshot.runningJobs)  review \(snapshot.reviewSignals)",
            x: 18,
            y: 45,
            size: 10,
            color: NSColor(calibratedWhite: 0.26, alpha: 1)
        )
        drawText(
            "Local estimates from Codex session logs",
            x: 18,
            y: 64,
            size: 9,
            color: NSColor(calibratedWhite: 0.42, alpha: 1)
        )

        drawProgressRow(
            title: "Context estimate",
            percent: token.remainingContextPercent,
            detail: contextDetail(token),
            x: 18,
            y: 86,
            width: 304,
            color: color(for: token.remainingContextPercent)
        )
        drawProgressRow(
            title: "5h quota window",
            percent: token.primaryLimit?.remainingPercent,
            detail: resetDetail(token.primaryLimit),
            x: 18,
            y: 139,
            width: 304,
            color: color(for: token.primaryLimit?.remainingPercent)
        )
        drawProgressRow(
            title: "7d quota window",
            percent: token.secondaryLimit?.remainingPercent,
            detail: resetDetail(token.secondaryLimit),
            x: 18,
            y: 192,
            width: 304,
            color: color(for: token.secondaryLimit?.remainingPercent)
        )

        drawText(
            "Turn \(formatCompact(token.currentTotalTokens ?? 0))  Today \(formatCompact(token.observedTodayTokens))  Week \(formatCompact(token.observedWeekTokens))",
            x: 18,
            y: 241,
            size: 10,
            color: NSColor(calibratedWhite: 0.20, alpha: 1)
        )
    }

    private func drawPanelBackground() {
        let bg = NSColor(calibratedRed: 1.00, green: 0.96, blue: 0.86, alpha: 1)
        let paper = NSColor(calibratedRed: 1.00, green: 0.91, blue: 0.66, alpha: 1)
        let shadow = NSColor(calibratedWhite: 0.08, alpha: 1)
        let edge = NSColor(calibratedRed: 0.58, green: 0.27, blue: 0.12, alpha: 1)
        let trim = NSColor(calibratedRed: 1.00, green: 0.77, blue: 0.35, alpha: 1)

        bg.setFill()
        bounds.fill()
        rect(8, 8, Int(bounds.width) - 16, Int(bounds.height) - 16, shadow)
        rect(10, 10, Int(bounds.width) - 20, Int(bounds.height) - 20, edge)
        rect(14, 14, Int(bounds.width) - 28, Int(bounds.height) - 28, paper)
        rect(18, 18, Int(bounds.width) - 36, 4, trim)
        rect(18, Int(bounds.height) - 24, Int(bounds.width) - 36, 4, trim)
    }

    private func drawProgressRow(title: String, percent: Double?, detail: String, x: Int, y: Int, width: Int, color: NSColor) {
        drawText(title, x: x, y: y, size: 11, weight: .semibold)
        drawText(formatPercent(percent ?? 0), x: x + width - 42, y: y, size: 11, weight: .bold)
        drawBar(percent: percent, x: x, y: y + 19, width: width, height: 15, color: color)
        drawText(detail, x: x, y: y + 38, size: 9, color: NSColor(calibratedWhite: 0.33, alpha: 1))
    }

    private func drawBar(percent: Double?, x: Int, y: Int, width: Int, height: Int, color: NSColor) {
        let outline = NSColor(calibratedWhite: 0.08, alpha: 1)
        let shell = NSColor(calibratedRed: 1.00, green: 0.80, blue: 0.42, alpha: 1)
        let well = NSColor(calibratedRed: 1.00, green: 0.94, blue: 0.72, alpha: 1)
        let shine = NSColor(calibratedRed: 1.00, green: 0.96, blue: 0.72, alpha: 1)
        let clamped = min(100, max(0, percent ?? 0))
        let fillWidth = Int((clamped / 100 * Double(width - 6)).rounded())

        rect(x, y, width, height, outline)
        rect(x + 1, y + 1, width - 2, height - 2, shell)
        rect(x + 3, y + 3, width - 6, height - 6, well)
        if fillWidth > 0 {
            rect(x + 3, y + 3, fillWidth, height - 6, color)
            rect(x + 4, y + 3, max(1, fillWidth - 2), 2, shine.withAlphaComponent(0.36))
        }

        for tick in stride(from: x + 36, through: x + width - 28, by: 36) {
            rect(tick, y + 3, 1, height - 6, outline.withAlphaComponent(0.18))
        }
    }

    private func drawPill(_ text: String, x: Int, y: Int, color: NSColor) {
        let width = 82
        rect(x, y, width, 18, NSColor(calibratedWhite: 0.08, alpha: 1))
        rect(x + 2, y + 2, width - 4, 14, color)
        drawText(text, x: x + 9, y: y + 3, size: 9, weight: .bold, color: NSColor(calibratedWhite: 0.08, alpha: 1))
    }

    private func contextDetail(_ token: TokenUsageSnapshot) -> String {
        guard let remaining = token.remainingContextTokens,
              let window = token.contextWindow
        else {
            return "Local token_count event not observed yet"
        }

        return "\(formatCompact(remaining)) left of \(formatCompact(window)) context window"
    }

    private func resetDetail(_ bucket: TokenBucketSnapshot?) -> String {
        guard let bucket else {
            return "Quota window not reported locally"
        }

        let reset = bucket.resetsAt.map {
            DateFormatter.localizedString(from: $0, dateStyle: .none, timeStyle: .short)
        } ?? "unknown"
        let window = bucket.windowMinutes >= 1440
            ? "\(bucket.windowMinutes / 1440)d"
            : String(format: "%.0fh", Double(bucket.windowMinutes) / 60)
        return "Window \(window), resets \(reset)"
    }

    private func stateColor(_ state: CatState) -> NSColor {
        switch state {
        case .idle:
            return NSColor(calibratedRed: 0.55, green: 0.72, blue: 1.00, alpha: 1)
        case .running:
            return NSColor(calibratedRed: 0.22, green: 0.92, blue: 0.54, alpha: 1)
        case .review:
            return NSColor(calibratedRed: 1.00, green: 0.28, blue: 0.28, alpha: 1)
        }
    }

    private func color(for percent: Double?) -> NSColor {
        let value = percent ?? 0
        if value < 20 {
            return NSColor(calibratedRed: 1.00, green: 0.12, blue: 0.16, alpha: 1)
        }
        if value < 45 {
            return NSColor(calibratedRed: 1.00, green: 0.58, blue: 0.12, alpha: 1)
        }
        return NSColor(calibratedRed: 0.12, green: 0.82, blue: 0.36, alpha: 1)
    }

    private func drawText(
        _ text: String,
        x: Int,
        y: Int,
        size: CGFloat,
        weight: NSFont.Weight = .regular,
        color: NSColor = NSColor(calibratedWhite: 0.08, alpha: 1)
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight),
            .foregroundColor: color
        ]
        text.draw(at: NSPoint(x: CGFloat(x), y: bounds.height - CGFloat(y) - size - 2), withAttributes: attributes)
    }

    private func rect(_ x: Int, _ yFromTop: Int, _ w: Int, _ h: Int, _ color: NSColor) {
        color.setFill()
        NSRect(
            x: CGFloat(x),
            y: bounds.height - CGFloat(yFromTop) - CGFloat(h),
            width: CGFloat(w),
            height: CGFloat(h)
        ).fill()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let animationInterval: TimeInterval = 0.16
    private let statusPollInterval: TimeInterval = 0.5
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let probe = CodexStatusProbe()
    private let icon = PixelStatusBadge()
    private var timer: Timer?
    private var frame = 0
    private var pollCount = 0
    private var lastSnapshot: StatusSnapshot?
    private var lastStatusPoll = Date.distantPast
    private let detailsPanel = TokenDetailsPanel(frame: NSRect(x: 0, y: 0, width: 340, height: 282))

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMenu()
        updateStatus()
        appendLog("launched")

        let refreshTimer = Timer(timeInterval: animationInterval, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
        timer = refreshTimer
        RunLoop.main.add(refreshTimer, forMode: .common)
    }

    private func configureMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let detailsItem = NSMenuItem()
        detailsItem.view = detailsPanel
        menu.addItem(detailsItem)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Codex Cat", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        statusItem.button?.title = ""
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.imageScaling = .scaleProportionallyUpOrDown
    }

    func menuWillOpen(_ menu: NSMenu) {
        lastStatusPoll = .distantPast
        updateStatus()
    }

    private func updateStatus() {
        let now = Date()
        var didPoll = false
        if lastSnapshot == nil || now.timeIntervalSince(lastStatusPoll) >= statusPollInterval {
            lastSnapshot = probe.snapshot()
            lastStatusPoll = now
            pollCount += 1
            didPoll = true
        }

        guard let snapshot = lastSnapshot else { return }

        frame += 1
        statusItem.button?.image = icon.image(state: snapshot.state, frame: frame, tokenUsage: snapshot.tokenUsage)
        statusItem.button?.toolTip = tooltipText(for: snapshot)
        if didPoll, pollCount.isMultiple(of: 10) {
            appendLog("state=\(snapshot.state.rawValue) conversation=\(snapshot.activeConversation) pending=\(snapshot.pendingCalls) jobs=\(snapshot.runningJobs) review=\(snapshot.reviewSignals) token=\(snapshot.tokenUsage.menuBarText)")
        }

        detailsPanel.snapshot = snapshot
    }

    private func tooltipText(for snapshot: StatusSnapshot) -> String {
        tooltipLines(for: snapshot).joined(separator: "\n")
    }

    private func tooltipLines(for snapshot: StatusSnapshot) -> [String] {
        let token = snapshot.tokenUsage
        let context: String
        if let remaining = token.remainingContextTokens,
           let window = token.contextWindow,
           let percent = token.remainingContextPercent {
            context = "Context estimate: \(formatBattery(percent)) left (\(formatCompact(remaining)) / \(formatCompact(window)))"
        } else {
            context = "Context estimate: unknown"
        }

        let current = token.currentTotalTokens.map { formatCompact($0) } ?? "unknown"
        let today = formatCompact(token.observedTodayTokens)
        let week = formatCompact(token.observedWeekTokens)

        return [
            "Codex is \(snapshot.state.rawValue)",
            "Signals: conversation \(snapshot.activeConversation), pending \(snapshot.pendingCalls), jobs \(snapshot.runningJobs), review \(snapshot.reviewSignals)",
            context,
            "Current turn observed: \(current)",
            "Today observed locally: \(today)",
            "This week observed locally: \(week)",
            "5h quota window: \(formatTokenBucket(token.primaryLimit))",
            "7d quota window: \(formatTokenBucket(token.secondaryLimit))"
        ]
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
    print("state=\(snapshot.state.rawValue) conversation=\(snapshot.activeConversation) pending=\(snapshot.pendingCalls) jobs=\(snapshot.runningJobs) review=\(snapshot.reviewSignals) token_left=\(snapshot.tokenUsage.menuBarText) today=\(formatCompact(snapshot.tokenUsage.observedTodayTokens)) week=\(formatCompact(snapshot.tokenUsage.observedWeekTokens))")
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
