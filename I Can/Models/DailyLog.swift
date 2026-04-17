import Foundation

// MARK: - Training Session (one per type)

struct TrainingSession: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var trainingType: String        // "match", "gym", "cardio", "technical", "tactical", "recovery", "other"
    var duration: Int               // Minutes
    var intensity: String           // Legacy field — kept for backward compat; new sessions use type-specific fields
    var details: [String]           // Type-specific selections (sub-options)
    var notes: String?

    // MARK: - Match fields
    var matchType: String?          // Legacy (deprecated — kept for backward compat)
    var result: String?             // "win", "loss", "draw"
    var winMethod: String?          // Sport-specific method of victory/result (e.g. "knockout", "split_decision")
    var performanceRating: Int?     // 1–10
    var minutesPlayed: Int?
    var position: String?
    var keyStats: [String: Int]?    // Sport-specific stats (goals, assists, etc.)

    // MARK: - Gym fields
    var gymFocus: String?           // "strength", "hypertrophy", "power", "conditioning"
    var effortLevel: String?        // "easy", "moderate", "hard", "failure"
    var exercises: [String]?

    // MARK: - Cardio fields
    var cardioType: String?         // "run", "walk", "bike", "swim", "row", "elliptical", etc.
    var distance: Double?           // stored in selected unit (see distanceUnit)
    var distanceUnit: String?       // "km" or "mi" (defaults to "km" when nil)
    var pace: String?               // e.g. "5:30 /km"
    var cardioEffort: String?       // "light", "moderate", "hard"

    // MARK: - Technical fields
    var skillTrained: String?
    var focusQuality: String?       // "poor", "average", "good", "elite"

    // MARK: - Tactical fields
    var tacticalType: String?       // "team_session", "analysis"
    var understandingLevel: String? // "low", "medium", "high"

    // MARK: - Recovery fields
    var recoveryType: String?       // "stretching", "ice_bath", "massage", "rest"

    // MARK: - Computed score
    var sessionScore: Int?          // 0–100, set after computation

    var trainingTypeDisplay: String {
        switch trainingType {
        case "match": return "Match"
        case "gym": return "Gym"
        case "cardio": return "Cardio"
        case "technical": return "Technical"
        case "tactical": return "Tactical"
        case "recovery": return "Recovery"
        case "other": return "Other"
        default: return trainingType.capitalized
        }
    }

    var intensityDisplay: String {
        // Prefer type-specific effort display over legacy intensity
        if let effort = effortLevel, !effort.isEmpty {
            return effort.capitalized
        }
        if let effort = cardioEffort, !effort.isEmpty {
            return effort.capitalized
        }
        if let quality = focusQuality, !quality.isEmpty {
            return quality.capitalized
        }
        switch intensity {
        case "low": return "Low"
        case "medium": return "Medium"
        case "high": return "High"
        case "max": return "Maximum"
        default: return intensity.capitalized
        }
    }

    var trainingTypeIcon: String {
        switch trainingType {
        case "match": return "trophy.fill"
        case "gym": return "dumbbell.fill"
        case "cardio": return "heart.circle.fill"
        case "technical": return "figure.run"
        case "tactical": return "brain.head.profile"
        case "recovery": return "leaf.fill"
        case "other": return "ellipsis.circle.fill"
        default: return "figure.run"
        }
    }

    // MARK: - Type-specific display helpers

    var resultDisplay: String? {
        guard let result else { return nil }
        switch result {
        case "win": return "Win"
        case "loss": return "Loss"
        case "draw": return "Draw"
        default: return result.capitalized
        }
    }

    var matchTypeDisplay: String? {
        guard let matchType else { return nil }
        switch matchType {
        case "match": return "Match"
        case "sparring": return "Sparring"
        case "competition": return "Competition"
        default: return matchType.capitalized
        }
    }

    var gymFocusDisplay: String? {
        guard let gymFocus else { return nil }
        switch gymFocus {
        case "strength": return "Strength"
        case "hypertrophy": return "Hypertrophy"
        case "power": return "Power"
        case "conditioning": return "Conditioning"
        default: return gymFocus.capitalized
        }
    }

    var effortLevelDisplay: String? {
        guard let effortLevel else { return nil }
        switch effortLevel {
        case "easy": return "Easy"
        case "moderate": return "Moderate"
        case "hard": return "Hard"
        case "failure": return "To Failure"
        default: return effortLevel.capitalized
        }
    }

    var cardioTypeDisplay: String? {
        guard let cardioType else { return nil }
        switch cardioType {
        case "run": return "Run"
        case "walk": return "Walk"
        case "bike": return "Bike"
        case "swim": return "Swim"
        default: return cardioType.capitalized
        }
    }

    var winMethodDisplay: String? {
        guard let winMethod, !winMethod.isEmpty else { return nil }
        return winMethod
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    var cardioEffortDisplay: String? {
        guard let cardioEffort else { return nil }
        switch cardioEffort {
        case "light": return "Light"
        case "moderate": return "Moderate"
        case "hard": return "Hard"
        default: return cardioEffort.capitalized
        }
    }

    var focusQualityDisplay: String? {
        guard let focusQuality else { return nil }
        switch focusQuality {
        case "poor": return "Poor"
        case "average": return "Average"
        case "good": return "Good"
        case "elite": return "Elite"
        default: return focusQuality.capitalized
        }
    }

    var tacticalTypeDisplay: String? {
        guard let tacticalType else { return nil }
        switch tacticalType {
        case "team_session": return "Team Session"
        case "analysis": return "Analysis"
        default: return tacticalType.capitalized
        }
    }

    var understandingLevelDisplay: String? {
        guard let understandingLevel else { return nil }
        switch understandingLevel {
        case "low": return "Low"
        case "medium": return "Medium"
        case "high": return "High"
        default: return understandingLevel.capitalized
        }
    }

    var recoveryTypeDisplay: String? {
        guard let recoveryType else { return nil }
        switch recoveryType {
        case "stretching": return "Stretching"
        case "ice_bath": return "Ice Bath"
        case "massage": return "Massage"
        case "rest": return "Rest"
        default: return recoveryType.capitalized
        }
    }

    /// Summary line for the session card
    var typeSpecificSummary: String {
        switch trainingType {
        case "match", "sparring":
            var parts: [String] = []
            if let r = resultDisplay { parts.append(r) }
            if let wm = winMethodDisplay { parts.append(wm) }
            if let pr = performanceRating { parts.append("\(pr)/10") }
            let fallback = trainingType == "sparring" ? "Sparring" : "Match"
            return parts.isEmpty ? fallback : parts.joined(separator: " - ")
        case "gym":
            var parts: [String] = []
            if let gf = gymFocusDisplay { parts.append(gf) }
            parts.append("\(duration)min")
            if let el = effortLevelDisplay { parts.append(el) }
            return parts.joined(separator: " - ")
        case "cardio":
            var parts: [String] = []
            if let ct = cardioTypeDisplay { parts.append(ct) }
            if let d = distance { parts.append(String(format: "%.1fkm", d)) }
            parts.append("\(duration)min")
            if let ce = cardioEffortDisplay { parts.append(ce) }
            return parts.joined(separator: " - ")
        case "technical":
            var parts: [String] = []
            if let st = skillTrained, !st.isEmpty { parts.append(st) }
            parts.append("\(duration)min")
            if let fq = focusQualityDisplay { parts.append(fq) }
            return parts.joined(separator: " - ")
        case "tactical":
            var parts: [String] = []
            if let tt = tacticalTypeDisplay { parts.append(tt) }
            parts.append("\(duration)min")
            if let ul = understandingLevelDisplay { parts.append(ul) }
            return parts.joined(separator: " - ")
        case "recovery":
            var parts: [String] = []
            if let rt = recoveryTypeDisplay { parts.append(rt) }
            if duration > 0 { parts.append("\(duration)min") }
            return parts.isEmpty ? "Recovery" : parts.joined(separator: " - ")
        default:
            return "\(duration)min"
        }
    }

    // MARK: - Session Score Computation

    mutating func computeAndSetScore() {
        sessionScore = computeScore()
    }

    func computeScore() -> Int {
        switch trainingType {
        case "match", "sparring":
            let ratingBase = (performanceRating ?? 5) * 8  // 8–80
            let minutesBonus = min((minutesPlayed ?? duration) / 9, 10)  // 0–10
            let resultBonus: Int
            switch result {
            case "win": resultBonus = 10
            case "draw": resultBonus = 5
            default: resultBonus = 0
            }
            return min(ratingBase + minutesBonus + resultBonus, 100)

        case "gym":
            let effortBase: Int
            switch effortLevel {
            case "easy": effortBase = 40
            case "moderate": effortBase = 60
            case "hard": effortBase = 80
            case "failure": effortBase = 90
            default: effortBase = 50
            }
            let durationBonus = min(duration / 12, 10)  // 60min = 5, 120min = 10
            return min(effortBase + durationBonus, 100)

        case "cardio":
            let effortBase: Int
            switch cardioEffort {
            case "light": effortBase = 50
            case "moderate": effortBase = 70
            case "hard": effortBase = 90
            default: effortBase = 60
            }
            let distBonus = min(Int((distance ?? 0) * 2), 10)
            return min(effortBase + distBonus, 100)

        case "technical":
            let qualityBase: Int
            switch focusQuality {
            case "poor": qualityBase = 30
            case "average": qualityBase = 50
            case "good": qualityBase = 70
            case "elite": qualityBase = 90
            default: qualityBase = 50
            }
            let durationBonus = min(duration / 12, 10)
            return min(qualityBase + durationBonus, 100)

        case "tactical":
            let understandingBase: Int
            switch understandingLevel {
            case "low": understandingBase = 40
            case "medium": understandingBase = 60
            case "high": understandingBase = 80
            default: understandingBase = 50
            }
            let durationBonus = min(duration / 12, 10)
            return min(understandingBase + durationBonus, 100)

        case "recovery":
            let durationBonus = min(duration / 6, 10)  // 60min = 10
            return min(60 + durationBonus, 100)

        default:
            // Legacy/other: use intensity fallback
            let intensityBase: Int
            switch intensity {
            case "low": intensityBase = 40
            case "medium": intensityBase = 60
            case "high": intensityBase = 80
            case "max": intensityBase = 95
            default: intensityBase = 50
            }
            let durationBonus = min(duration / 12, 10)
            return min(intensityBase + durationBonus, 100)
        }
    }

    /// Sub-options available for each training type
    static func detailOptions(for type: String, sport: String) -> [String] {
        switch type {
        case "match":
            return matchDetails(sport: sport)
        case "gym":
            return ["Upper Body", "Lower Body", "Core", "Full Body", "Push", "Pull", "Legs", "Arms", "Back", "Chest", "Shoulders"]
        case "cardio":
            return ["Running", "Cycling", "Swimming", "HIIT", "Rowing", "Jump Rope", "Sprints", "Long Distance", "Interval Training"]
        case "technical":
            return technicalDetails(sport: sport)
        case "tactical":
            return tacticalDetails(sport: sport)
        case "recovery":
            return ["Stretching", "Foam Rolling", "Ice Bath", "Massage", "Yoga", "Mobility Work", "Light Walk", "Meditation", "Compression"]
        case "other":
            return ["Cross Training", "Team Building", "Warm Up", "Cool Down", "Testing", "Assessment"]
        default:
            return []
        }
    }

    /// Sport-specific "how did the result happen" methods. Shown after the user picks Win/Loss/Draw.
    /// Returns `[(value, label)]` — empty if the sport has no meaningful follow-up (in which case the UI hides it).
    static func matchWinMethods(sport: String) -> [(String, String)] {
        switch sport.lowercased() {
        case "boxing":
            return [
                ("knockout", "Knockout"),
                ("technical_knockout", "TKO"),
                ("unanimous_decision", "Unanimous Decision"),
                ("split_decision", "Split Decision"),
                ("majority_decision", "Majority Decision"),
                ("disqualification", "Disqualification")
            ]
        case "soccer":
            return [
                ("clean_sheet", "Clean Sheet"),
                ("narrow_margin", "Narrow Margin"),
                ("dominant", "Dominant"),
                ("comeback", "Comeback"),
                ("penalties", "Penalty Shootout"),
                ("extra_time", "Extra Time")
            ]
        case "basketball":
            return [
                ("blowout", "Blowout"),
                ("close_game", "Close Game"),
                ("overtime", "Overtime"),
                ("buzzer_beater", "Buzzer Beater"),
                ("comeback", "Comeback")
            ]
        case "tennis":
            return [
                ("straight_sets", "Straight Sets"),
                ("three_sets", "Three Sets"),
                ("tiebreak", "Tiebreak"),
                ("comeback", "Comeback"),
                ("retirement", "Retirement")
            ]
        case "football":
            return [
                ("dominant", "Dominant"),
                ("close_game", "Close Game"),
                ("overtime", "Overtime"),
                ("comeback", "Comeback"),
                ("shutout", "Shutout")
            ]
        case "cricket":
            return [
                ("by_runs", "By Runs"),
                ("by_wickets", "By Wickets"),
                ("super_over", "Super Over"),
                ("duckworth_lewis", "DLS Method"),
                ("innings", "By Innings")
            ]
        default:
            return [
                ("dominant", "Dominant"),
                ("close_game", "Close"),
                ("comeback", "Comeback")
            ]
        }
    }

    static func matchDetails(sport: String) -> [String] {
        switch sport.lowercased() {
        case "soccer":
            return ["Full Match", "Friendly", "Tournament", "Started", "Came Off Bench", "Win", "Loss", "Draw", "Scored", "Assisted", "Clean Sheet"]
        case "basketball":
            return ["Full Game", "Scrimmage", "Tournament", "Started", "Off Bench", "Win", "Loss", "Double Digits", "Clutch Performance"]
        case "tennis":
            return ["Singles", "Doubles", "Tournament", "Practice Match", "Win", "Loss", "Tiebreak", "Straight Sets", "Comeback"]
        case "boxing":
            return ["Sparring", "Exhibition", "Competition", "Rounds Completed", "Win", "Loss", "Draw", "Stoppage", "Decision"]
        case "football":
            return ["Full Game", "Scrimmage", "Started", "Off Bench", "Win", "Loss", "Touchdown", "Turnover Free", "Key Play"]
        case "cricket":
            return ["T20", "ODI", "Test", "Practice Match", "Batted", "Bowled", "Fielded", "Win", "Loss", "Draw", "Man of Match"]
        default:
            return ["Full Match", "Practice Match", "Tournament", "Started", "Substitute", "Win", "Loss", "Draw"]
        }
    }

    static func technicalDetails(sport: String) -> [String] {
        switch sport.lowercased() {
        case "soccer":
            return ["Shooting", "Passing", "Dribbling", "First Touch", "Crossing", "Heading", "Free Kicks", "Penalties", "Ball Control", "Weak Foot", "Team Training"]
        case "basketball":
            return ["Shooting Form", "Free Throws", "3-Pointers", "Ball Handling", "Passing", "Post Moves", "Layups", "Dunking", "Crossovers", "Scrimmage", "Team Training"]
        case "tennis":
            return ["Serve", "Return", "Forehand", "Backhand", "Volley", "Slice", "Topspin", "Drop Shot", "Lob", "Overhead"]
        case "boxing":
            return ["Sparring", "Jab", "Cross", "Hook", "Uppercut", "Body Shots", "Combinations", "Counter Punching", "Head Movement", "Footwork", "Defense"]
        case "football":
            return ["Throwing Mechanics", "Route Running", "Catching", "Blocking", "Tackling Form", "Footwork", "Hand Placement", "Release", "Coverage", "Team Training"]
        case "cricket":
            return ["Batting Technique", "Bowling Action", "Spin", "Pace", "Swing", "Fielding Drills", "Catching", "Throwing", "Running Between Wickets", "Team Training"]
        default:
            return ["Skill Drills", "Technique Work", "Repetition Training", "Form Correction", "Fundamentals", "Advanced Skills"]
        }
    }

    static func tacticalDetails(sport: String) -> [String] {
        switch sport.lowercased() {
        case "soccer":
            return ["Formation Work", "Set Pieces", "Pressing", "Build-up Play", "Counter Attack", "Defensive Shape", "Video Analysis", "Positioning", "Transitions"]
        case "basketball":
            return ["Offensive Sets", "Defensive Schemes", "Pick & Roll", "Fast Break", "Zone Defense", "Man-to-Man", "Inbounds Plays", "Film Study", "Spacing"]
        case "tennis":
            return ["Serve Strategy", "Return Strategy", "Court Positioning", "Point Construction", "Net Play", "Match Analysis", "Opponent Study", "Surface Adaptation"]
        case "boxing":
            return ["Fight Strategy", "Ring Generalship", "Distance Control", "Pressure Fighting", "Counter Strategy", "Clinch Work", "Opponent Study", "Round Management"]
        case "football":
            return ["Playbook Study", "Film Review", "Audibles", "Blitz Schemes", "Coverage Reads", "Red Zone", "2-Minute Drill", "Special Teams", "Game Planning"]
        case "cricket":
            return ["Field Placement", "Bowling Strategy", "Batting Order", "Match Situation", "Death Overs", "Powerplay", "DRS Strategy", "Pitch Reading", "Weather Tactics"]
        default:
            return ["Game Plan", "Strategy Review", "Video Analysis", "Positioning", "Team Tactics", "Set Plays"]
        }
    }
}

// MARK: - Training Data (container for multiple sessions)

struct TrainingData: Codable, Equatable {
    var sessions: [TrainingSession]
    var sport: String?

    var totalDuration: Int {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var sessionCount: Int { sessions.count }

    var summaryText: String {
        if sessions.isEmpty { return "No sessions" }
        if sessions.count == 1, let s = sessions.first {
            return s.typeSpecificSummary
        }
        let types = sessions.map { $0.trainingTypeDisplay }
        let unique = Array(Set(types))
        return "\(unique.joined(separator: " + ")) - \(totalDuration)min"
    }

    var averageSessionScore: Int {
        let scores = sessions.map { $0.sessionScore ?? $0.computeScore() }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / scores.count
    }

    var highestIntensity: String {
        let order = ["max", "high", "medium", "low"]
        for level in order {
            if sessions.contains(where: { $0.intensity == level }) { return level }
        }
        return "medium"
    }

    var highestIntensityDisplay: String {
        TrainingSession(trainingType: "", duration: 0, intensity: highestIntensity, details: []).intensityDisplay
    }
}

// MARK: - Nutrition Data

struct NutritionData: Codable, Equatable {
    var breakfast: String?
    var lunch: String?
    var dinner: String?
    var snacks: String?
    var drinks: String?

    var mealsLogged: Int {
        [breakfast, lunch, dinner].compactMap { $0 }.filter { !$0.isEmpty }.count
    }

    var summary: String {
        let meals = [("Breakfast", breakfast), ("Lunch", lunch), ("Dinner", dinner)]
            .compactMap { name, val in
                guard let v = val, !v.isEmpty else { return nil as String? }
                return name
            }
        if meals.isEmpty { return "No meals logged" }
        return meals.joined(separator: ", ")
    }
}

// MARK: - Sleep Data

struct SleepData: Codable, Equatable {
    var sleepTime: String           // "HH:mm" format
    var wakeTime: String            // "HH:mm" format

    var durationHours: Double {
        guard let sleep = parseTime(sleepTime),
              let wake = parseTime(wakeTime) else { return 0 }
        var diff = wake - sleep
        if diff < 0 { diff += 24 * 60 }
        return Double(diff) / 60.0
    }

    var durationFormatted: String {
        let hours = Int(durationHours)
        let minutes = Int((durationHours - Double(hours)) * 60)
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(minutes)m"
    }

    private func parseTime(_ time: String) -> Int? {
        let parts = time.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]) else { return nil }
        return h * 60 + m
    }
}

// MARK: - Daily Log Responses (v2)

struct DailyLogResponses: Codable {
    var version: Int = 2
    var training: TrainingData?
    var nutrition: NutritionData?
    var sleep: SleepData?
    var completedSections: [String]

    var completionCount: Int { completedSections.count }
    var isFullyComplete: Bool { completionCount == 3 }

    var hasTraining: Bool { completedSections.contains("training") }
    var hasNutrition: Bool { completedSections.contains("nutrition") }
    var hasSleep: Bool { completedSections.contains("sleep") }
}

// MARK: - DailyEntry extension for v2

extension DailyEntry {
    var isDailyLog: Bool { responses?.version == 2 }

    var dailyLogResponses: DailyLogResponses? {
        responses?.dailyLog
    }

    var logCompletionCount: Int {
        dailyLogResponses?.completionCount ?? 0
    }
}

// MARK: - EntryResponses extension for v2

extension EntryResponses {
    var dailyLog: DailyLogResponses? {
        guard version == 2 else { return nil }
        return DailyLogResponses(
            version: 2,
            training: training,
            nutrition: nutrition,
            sleep: sleep,
            completedSections: completedSections ?? []
        )
    }
}

// MARK: - Submit Request for Daily Log

struct DailyLogSubmitRequest: Encodable {
    let entryDate: String
    let responses: DailyLogSubmitResponses
}

struct DailyLogSubmitResponses: Encodable {
    let version: Int = 2
    let training: TrainingData?
    let nutrition: NutritionData?
    let sleep: SleepData?
    let completedSections: [String]
}
