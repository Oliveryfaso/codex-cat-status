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
    let observedTokens: Int
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

    var menuBarQuotaPercent: Double? {
        primaryLimit?.remainingPercent
    }

    var menuBarText: String {
        guard let menuBarQuotaPercent else { return "[------] --" }
        return formatBattery(menuBarQuotaPercent, width: 6, includePercent: true)
    }
}

struct SessionActivityState {
    var offset: UInt64 = 0
    var partialLine = ""
    var latestStartedTurn: String?
    var latestStartedAt: Date?
    var completedTurns = Set<String>()
    var pending: [String: PendingCallRecord] = [:]
    var tokenEventsByTurn: [String: TokenUsageRecord] = [:]
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
        drawBattery(percent: tokenUsage.menuBarQuotaPercent)

        image.unlockFocus()
        return image
    }

    private func drawBattery(percent: Double?) {
        let x = 34
        let y = 3
        let bodyWidth = 10
        let bodyHeight = 18
        let hasKnownPercent = percent != nil
        let clamped = min(100, max(0, percent ?? 0))
        let innerHeight = bodyHeight - 4
        var fillHeight = Int((clamped / 100 * Double(innerHeight)).rounded())
        if hasKnownPercent, clamped <= 5 {
            fillHeight = 2
        }
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
        let observedTotal = observedTokenTotal(from: lastUsage) ?? lastTotal
        if observedTotal > 0 {
            let turnKey = state.latestStartedTurn ?? "session"
            let existing = state.tokenEventsByTurn[turnKey]
            if existing == nil || timestamp >= existing!.date {
                state.tokenEventsByTurn[turnKey] = TokenUsageRecord(date: timestamp, observedTokens: observedTotal)
            }
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
        state.tokenEventsByTurn = state.tokenEventsByTurn.filter { $0.value.date >= weekAgo }
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
            for event in state.tokenEventsByTurn.values {
                if event.date >= startOfToday {
                    today += event.observedTokens
                }
                if event.date >= startOfWeek {
                    week += event.observedTokens
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

    private func observedTokenTotal(from usage: [String: Any]?) -> Int? {
        guard let usage else { return nil }

        let input = intValue(usage["input_tokens"])
        let cachedInput = intValue(usage["cached_input_tokens"]) ?? 0
        let output = intValue(usage["output_tokens"]) ?? 0

        if let input {
            return max(0, input - cachedInput) + output
        }

        return intValue(usage["total_tokens"])
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
    var onQuit: (() -> Void)?

    var snapshot: StatusSnapshot? {
        didSet {
            needsDisplay = true
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 336, height: 218)
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
            drawText("Reading Codex status", x: 24, y: 24, size: 14, weight: .semibold, color: palette.primaryText)
            return
        }

        let token = snapshot.tokenUsage
        drawText("Codex Cat", x: 24, y: 20, size: 17, weight: .semibold, color: palette.primaryText)
        drawStatusPill(snapshot.state.rawValue.uppercased(), x: 238, y: 18, width: 74, state: snapshot.state)

        drawText(
            "conv \(snapshot.activeConversation)  ·  pending \(snapshot.pendingCalls)  ·  review \(snapshot.reviewSignals)",
            x: 24,
            y: 48,
            size: 11,
            color: palette.secondaryText
        )

        drawQuotaRow(
            title: "5h quota",
            percent: token.primaryLimit?.remainingPercent,
            detail: resetDetail(token.primaryLimit),
            y: 74
        )
        drawQuotaRow(
            title: "7d quota",
            percent: token.secondaryLimit?.remainingPercent,
            detail: resetDetail(token.secondaryLimit),
            y: 126
        )

        drawText(
            "Local quota estimate · may differ from Codex UI",
            x: 24,
            y: 184,
            size: 10,
            color: palette.tertiaryText
        )
        drawQuitButton()
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if quitButtonRect.contains(point) {
            onQuit?()
        } else {
            super.mouseDown(with: event)
        }
    }

    private func drawPanelBackground() {
        NSColor.clear.setFill()
        bounds.fill()

        let cardRect = bounds.insetBy(dx: 12, dy: 10)
        let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 18, yRadius: 18)

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(palette.isDark ? 0.34 : 0.18)
        shadow.shadowBlurRadius = 18
        shadow.shadowOffset = NSSize(width: 0, height: -5)
        shadow.set()
        palette.cardFill.setFill()
        cardPath.fill()
        NSGraphicsContext.restoreGraphicsState()

        palette.cardFill.setFill()
        cardPath.fill()
        palette.cardStroke.setStroke()
        cardPath.lineWidth = 1
        cardPath.stroke()

        let highlight = rectFromTop(x: 24, y: 16, width: Int(bounds.width) - 48, height: 1)
        palette.cardHighlight.setFill()
        NSBezierPath(roundedRect: highlight, xRadius: 0.5, yRadius: 0.5).fill()
    }

    private func drawQuotaRow(title: String, percent: Double?, detail: String, y: Int) {
        let x = 24
        let width = Int(bounds.width) - 48
        drawText(title, x: x, y: y, size: 12, weight: .medium, color: palette.primaryText)
        drawRightText(formatPercent(percent ?? 0), right: 24, y: y - 2, size: 18, weight: .semibold, color: palette.primaryText)
        drawBar(percent: percent, x: x, y: y + 26, width: width, height: 9, color: color(for: percent))
        drawText(detail, x: x, y: y + 42, size: 10, color: palette.secondaryText)
    }

    private func drawBar(percent: Double?, x: Int, y: Int, width: Int, height: Int, color: NSColor) {
        let clamped = min(100, max(0, percent ?? 0))
        let trackRect = rectFromTop(x: x, y: y, width: width, height: height)
        var fillWidth = Int((clamped / 100 * Double(width)).rounded())
        if clamped > 0 {
            fillWidth = max(5, fillWidth)
        }

        palette.trackFill.setFill()
        NSBezierPath(roundedRect: trackRect, xRadius: CGFloat(height) / 2, yRadius: CGFloat(height) / 2).fill()

        if fillWidth > 0 {
            let fillRect = NSRect(x: trackRect.minX, y: trackRect.minY, width: CGFloat(fillWidth), height: trackRect.height)
            color.setFill()
            NSBezierPath(roundedRect: fillRect, xRadius: CGFloat(height) / 2, yRadius: CGFloat(height) / 2).fill()
        }

        palette.trackStroke.setStroke()
        let outline = NSBezierPath(roundedRect: trackRect, xRadius: CGFloat(height) / 2, yRadius: CGFloat(height) / 2)
        outline.lineWidth = 0.8
        outline.stroke()
    }

    private func drawStatusPill(_ text: String, x: Int, y: Int, width: Int, state: CatState) {
        let color = stateColor(state)
        let rect = rectFromTop(x: x, y: y, width: width, height: 24)
        color.withAlphaComponent(palette.isDark ? 0.22 : 0.14).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12).fill()
        color.withAlphaComponent(0.42).setStroke()
        let outline = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)
        outline.lineWidth = 1
        outline.stroke()

        let dot = rectFromTop(x: x + 10, y: y + 8, width: 8, height: 8)
        color.setFill()
        NSBezierPath(ovalIn: dot).fill()
        drawText(text, x: x + 24, y: y + 6, size: 10, weight: .semibold, color: palette.primaryText)
    }

    private func drawQuitButton() {
        let rect = quitButtonRect
        palette.buttonFill.setFill()
        NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10).fill()
        palette.cardStroke.setStroke()
        let outline = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)
        outline.lineWidth = 1
        outline.stroke()
        drawCenteredText("Quit", in: rect, size: 10, weight: .medium, color: palette.secondaryText)
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
        return "\(formatPercent(bucket.usedPercent)) used · \(window) window · resets \(reset)"
    }

    private func stateColor(_ state: CatState) -> NSColor {
        switch state {
        case .idle:
            return .systemBlue
        case .running:
            return .systemGreen
        case .review:
            return .systemRed
        }
    }

    private func color(for percent: Double?) -> NSColor {
        let value = percent ?? 0
        if value < 20 {
            return .systemRed
        }
        if value < 45 {
            return .systemOrange
        }
        return .systemGreen
    }

    private func drawText(
        _ text: String,
        x: Int,
        y: Int,
        size: CGFloat,
        weight: NSFont.Weight = .regular,
        color: NSColor
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color
        ]
        text.draw(at: NSPoint(x: CGFloat(x), y: bounds.height - CGFloat(y) - size - 2), withAttributes: attributes)
    }

    private func drawRightText(_ text: String, right: Int, y: Int, size: CGFloat, weight: NSFont.Weight, color: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight),
            .foregroundColor: color
        ]
        let textSize = text.size(withAttributes: attributes)
        text.draw(
            at: NSPoint(x: bounds.width - CGFloat(right) - textSize.width, y: bounds.height - CGFloat(y) - size - 2),
            withAttributes: attributes
        )
    }

    private func drawCenteredText(_ text: String, in rect: NSRect, size: CGFloat, weight: NSFont.Weight, color: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color
        ]
        let textSize = text.size(withAttributes: attributes)
        text.draw(
            at: NSPoint(x: rect.midX - textSize.width / 2, y: rect.midY - textSize.height / 2),
            withAttributes: attributes
        )
    }

    private var quitButtonRect: NSRect {
        rectFromTop(x: Int(bounds.width) - 76, y: 176, width: 52, height: 24)
    }

    private func rectFromTop(x: Int, y: Int, width: Int, height: Int) -> NSRect {
        NSRect(
            x: CGFloat(x),
            y: bounds.height - CGFloat(y) - CGFloat(height),
            width: CGFloat(width),
            height: CGFloat(height)
        )
    }

    private var palette: PanelPalette {
        let dark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if dark {
            return PanelPalette(
                isDark: true,
                cardFill: NSColor(calibratedWhite: 0.12, alpha: 0.78),
                cardStroke: NSColor.white.withAlphaComponent(0.18),
                cardHighlight: NSColor.white.withAlphaComponent(0.24),
                primaryText: NSColor.white.withAlphaComponent(0.94),
                secondaryText: NSColor.white.withAlphaComponent(0.62),
                tertiaryText: NSColor.white.withAlphaComponent(0.42),
                trackFill: NSColor.white.withAlphaComponent(0.12),
                trackStroke: NSColor.white.withAlphaComponent(0.14),
                buttonFill: NSColor.white.withAlphaComponent(0.08)
            )
        }

        return PanelPalette(
            isDark: false,
            cardFill: NSColor.white.withAlphaComponent(0.82),
            cardStroke: NSColor.white.withAlphaComponent(0.72),
            cardHighlight: NSColor.white.withAlphaComponent(0.92),
            primaryText: NSColor.black.withAlphaComponent(0.86),
            secondaryText: NSColor.black.withAlphaComponent(0.52),
            tertiaryText: NSColor.black.withAlphaComponent(0.42),
            trackFill: NSColor.black.withAlphaComponent(0.08),
            trackStroke: NSColor.black.withAlphaComponent(0.08),
            buttonFill: NSColor.black.withAlphaComponent(0.045)
        )
    }
}

private struct PanelPalette {
    let isDark: Bool
    let cardFill: NSColor
    let cardStroke: NSColor
    let cardHighlight: NSColor
    let primaryText: NSColor
    let secondaryText: NSColor
    let tertiaryText: NSColor
    let trackFill: NSColor
    let trackStroke: NSColor
    let buttonFill: NSColor
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let animationInterval: TimeInterval = 0.16
    private let statusPollInterval: TimeInterval = 0.5
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let probe = CodexStatusProbe()
    private let probeQueue = DispatchQueue(label: "CodexCatStatus.probe", qos: .utility)
    private let icon = PixelStatusBadge()
    private var timer: Timer?
    private var frame = 0
    private var pollCount = 0
    private var lastSnapshot: StatusSnapshot?
    private var lastStatusPoll = Date.distantPast
    private var isProbeRunning = false
    private var menuCloseTimer: Timer?
    private var menuMouseOutsideSince: Date?
    private let menuAutoCloseDelay: TimeInterval = 1.5
    private let detailsPanel = TokenDetailsPanel(frame: NSRect(x: 0, y: 0, width: 340, height: 230))

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

        detailsPanel.onQuit = { [weak self] in
            self?.quit()
        }
        let detailsItem = NSMenuItem()
        detailsItem.view = detailsPanel
        menu.addItem(detailsItem)

        statusItem.menu = menu
        statusItem.button?.title = ""
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.imageScaling = .scaleProportionallyUpOrDown
        statusItem.button?.toolTip = nil
    }

    func menuWillOpen(_ menu: NSMenu) {
        if let lastSnapshot {
            detailsPanel.snapshot = lastSnapshot
        }
        startMenuAutoCloseTimer(for: menu)
        requestStatusPoll(force: true)
    }

    func menuDidClose(_ menu: NSMenu) {
        stopMenuAutoCloseTimer()
    }

    private func updateStatus() {
        let now = Date()
        if lastSnapshot == nil || now.timeIntervalSince(lastStatusPoll) >= statusPollInterval {
            requestStatusPoll(force: lastSnapshot == nil)
        }

        guard let snapshot = lastSnapshot else { return }

        render(snapshot: snapshot, didPoll: false)
    }

    private func requestStatusPoll(force: Bool = false) {
        let now = Date()
        guard !isProbeRunning else { return }
        guard force || now.timeIntervalSince(lastStatusPoll) >= statusPollInterval else { return }

        isProbeRunning = true
        lastStatusPoll = now
        probeQueue.async { [weak self] in
            guard let self else { return }
            let snapshot = self.probe.snapshot()
            DispatchQueue.main.async {
                self.lastSnapshot = snapshot
                self.isProbeRunning = false
                self.pollCount += 1
                self.render(snapshot: snapshot, didPoll: true)
            }
        }
    }

    private func render(snapshot: StatusSnapshot, didPoll: Bool) {
        frame += 1
        statusItem.button?.image = icon.image(state: snapshot.state, frame: frame, tokenUsage: snapshot.tokenUsage)
        statusItem.button?.toolTip = nil
        if didPoll, pollCount.isMultiple(of: 10) {
            appendLog("state=\(snapshot.state.rawValue) conversation=\(snapshot.activeConversation) pending=\(snapshot.pendingCalls) jobs=\(snapshot.runningJobs) review=\(snapshot.reviewSignals) token=\(snapshot.tokenUsage.menuBarText)")
        }

        detailsPanel.snapshot = snapshot
    }

    private func startMenuAutoCloseTimer(for menu: NSMenu) {
        stopMenuAutoCloseTimer()
        menuMouseOutsideSince = nil

        let closeTimer = Timer(timeInterval: 0.25, repeats: true) { [weak self, weak menu] _ in
            guard let self, let menu else { return }
            self.updateMenuAutoClose(menu: menu)
        }
        menuCloseTimer = closeTimer
        RunLoop.main.add(closeTimer, forMode: .common)
    }

    private func stopMenuAutoCloseTimer() {
        menuCloseTimer?.invalidate()
        menuCloseTimer = nil
        menuMouseOutsideSince = nil
    }

    private func updateMenuAutoClose(menu: NSMenu) {
        guard let menuWindow = detailsPanel.window else { return }

        let mouse = NSEvent.mouseLocation
        let menuFrame = menuWindow.frame.insetBy(dx: -16, dy: -16)
        let buttonFrame = statusButtonFrame()?.insetBy(dx: -12, dy: -12) ?? .zero

        if menuFrame.contains(mouse) || buttonFrame.contains(mouse) {
            menuMouseOutsideSince = nil
            return
        }

        let now = Date()
        if let outsideSince = menuMouseOutsideSince {
            if now.timeIntervalSince(outsideSince) >= menuAutoCloseDelay {
                menu.cancelTracking()
                stopMenuAutoCloseTimer()
            }
        } else {
            menuMouseOutsideSince = now
        }
    }

    private func statusButtonFrame() -> NSRect? {
        guard let button = statusItem.button,
              let window = button.window
        else {
            return nil
        }

        let frameInWindow = button.convert(button.bounds, to: nil)
        return window.convertToScreen(frameInWindow)
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
