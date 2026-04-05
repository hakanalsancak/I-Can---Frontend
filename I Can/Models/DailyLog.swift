import Foundation

// MARK: - Training Session (one per type)

struct TrainingSession: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var trainingType: String        // "match", "gym", "cardio", "technical", "tactical", "recovery", "other"
    var duration: Int               // Minutes
    var intensity: String           // "low", "medium", "high", "max"
    var details: [String]           // Type-specific selections (sub-options)
    var notes: String?

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

    private static func matchDetails(sport: String) -> [String] {
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

    private static func technicalDetails(sport: String) -> [String] {
        switch sport.lowercased() {
        case "soccer":
            return ["Shooting", "Passing", "Dribbling", "First Touch", "Crossing", "Heading", "Free Kicks", "Penalties", "Ball Control", "Weak Foot"]
        case "basketball":
            return ["Shooting Form", "Free Throws", "3-Pointers", "Ball Handling", "Passing", "Post Moves", "Layups", "Dunking", "Crossovers"]
        case "tennis":
            return ["Serve", "Return", "Forehand", "Backhand", "Volley", "Slice", "Topspin", "Drop Shot", "Lob", "Overhead"]
        case "boxing":
            return ["Jab", "Cross", "Hook", "Uppercut", "Body Shots", "Combinations", "Counter Punching", "Head Movement", "Footwork", "Defense"]
        case "football":
            return ["Throwing Mechanics", "Route Running", "Catching", "Blocking", "Tackling Form", "Footwork", "Hand Placement", "Release", "Coverage"]
        case "cricket":
            return ["Batting Technique", "Bowling Action", "Spin", "Pace", "Swing", "Fielding Drills", "Catching", "Throwing", "Running Between Wickets"]
        default:
            return ["Skill Drills", "Technique Work", "Repetition Training", "Form Correction", "Fundamentals", "Advanced Skills"]
        }
    }

    private static func tacticalDetails(sport: String) -> [String] {
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
        let types = sessions.map { $0.trainingTypeDisplay }
        let unique = Array(Set(types))
        if unique.count == 1 {
            return "\(unique[0]) - \(totalDuration)min"
        }
        return "\(unique.joined(separator: " + ")) - \(totalDuration)min"
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
    var isDailyLog: Bool { activityType == "daily_log" }

    var dailyLogResponses: DailyLogResponses? {
        guard isDailyLog, let responses else { return nil }
        // Decode from the generic EntryResponses to DailyLogResponses
        // We store v2 data in the responses JSONB
        return responses.dailyLog
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
    let activityType: String = "daily_log"
    let focusRating: Int
    let effortRating: Int
    let confidenceRating: Int
    let responses: DailyLogSubmitResponses
}

struct DailyLogSubmitResponses: Encodable {
    let version: Int = 2
    let training: TrainingData?
    let nutrition: NutritionData?
    let sleep: SleepData?
    let completedSections: [String]
}
