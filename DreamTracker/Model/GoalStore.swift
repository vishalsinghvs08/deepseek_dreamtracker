import Foundation

// MARK: - Goal Store Protocol

public protocol GoalStoreProtocol {
    // Goal
    func saveGoal(_ goal: Goal) async throws
    func fetchGoal() async throws -> Goal?

    // Habits
    func saveHabit(_ habit: Habit) async throws
    func fetchHabits() async throws -> [Habit]
    func toggleHabit(id: UUID) async throws
    func deleteHabit(id: UUID) async throws

    // Milestones
    func saveMilestone(_ milestone: Milestone) async throws
    func fetchMilestones() async throws -> [Milestone]
    func toggleMilestone(id: UUID) async throws

    // Reflections
    func saveReflection(_ reflection: Reflection) async throws
    func fetchReflections() async throws -> [Reflection]
    func deleteReflection(id: UUID) async throws

    // Destroy all data
    func destroyAll() throws
}

// MARK: - Goal Store Implementation

public final class GoalStore: GoalStoreProtocol {
    private let documentsURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init() {
        documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        encoder.outputFormatting = .prettyPrinted
    }

    // MARK: Paths

    private var goalURL: URL {
        documentsURL.appendingPathComponent("goal.json")
    }

    private var habitsURL: URL {
        documentsURL.appendingPathComponent("habits.json")
    }

    private var milestonesURL: URL {
        documentsURL.appendingPathComponent("milestones.json")
    }

    private var reflectionsURL: URL {
        documentsURL.appendingPathComponent("reflections.json")
    }

    // MARK: Goal

    public func saveGoal(_ goal: Goal) async throws {
        let data = try encoder.encode(goal)
        try writeProtected(data: data, to: goalURL)
    }

    public func fetchGoal() async throws -> Goal? {
        guard FileManager.default.fileExists(atPath: goalURL.path) else { return nil }
        let data = try Data(contentsOf: goalURL)
        return try decoder.decode(Goal.self, from: data)
    }

    // MARK: Habits

    public func saveHabit(_ habit: Habit) async throws {
        var habits = try await fetchHabits()
        if let idx = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[idx] = habit
        } else {
            habits.append(habit)
        }
        let data = try encoder.encode(habits)
        try writeProtected(data: data, to: habitsURL)
    }

    public func fetchHabits() async throws -> [Habit] {
        guard FileManager.default.fileExists(atPath: habitsURL.path) else { return [] }
        let data = try Data(contentsOf: habitsURL)
        return try decoder.decode([Habit].self, from: data)
    }

    public func toggleHabit(id: UUID) async throws {
        var habits = try await fetchHabits()
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        var habit = habits[idx]
        habit.isCompletedToday.toggle()
        if habit.isCompletedToday {
            let today = Calendar.current.startOfDay(for: Date())
            if let last = habit.lastCompletedAt {
                let lastDay = Calendar.current.startOfDay(for: last)
                let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
                if diff == 1 {
                    habit.streakDays += 1
                } else if diff > 1 {
                    habit.streakDays = 1
                }
            } else {
                habit.streakDays = 1
            }
            habit.lastCompletedAt = Date()
        } else {
            habit.streakDays = max(0, habit.streakDays - 1)
        }
        habits[idx] = habit
        let data = try encoder.encode(habits)
        try writeProtected(data: data, to: habitsURL)
    }

    public func deleteHabit(id: UUID) async throws {
        var habits = try await fetchHabits()
        habits.removeAll { $0.id == id }
        let data = try encoder.encode(habits)
        try writeProtected(data: data, to: habitsURL)
    }

    // MARK: Milestones

    public func saveMilestone(_ milestone: Milestone) async throws {
        var milestones = try await fetchMilestones()
        if let idx = milestones.firstIndex(where: { $0.id == milestone.id }) {
            milestones[idx] = milestone
        } else {
            milestones.append(milestone)
        }
        let data = try encoder.encode(milestones)
        try writeProtected(data: data, to: milestonesURL)
    }

    public func fetchMilestones() async throws -> [Milestone] {
        guard FileManager.default.fileExists(atPath: milestonesURL.path) else { return [] }
        let data = try Data(contentsOf: milestonesURL)
        return try decoder.decode([Milestone].self, from: data)
    }

    public func toggleMilestone(id: UUID) async throws {
        var milestones = try await fetchMilestones()
        guard let idx = milestones.firstIndex(where: { $0.id == id }) else { return }
        var milestone = milestones[idx]
        milestone.isCompleted.toggle()
        milestone.completedAt = milestone.isCompleted ? Date() : nil
        milestones[idx] = milestone
        let data = try encoder.encode(milestones)
        try writeProtected(data: data, to: milestonesURL)
    }

    // MARK: Reflections

    public func saveReflection(_ reflection: Reflection) async throws {
        var reflections = try await fetchReflections()
        if let idx = reflections.firstIndex(where: { $0.id == reflection.id }) {
            reflections[idx] = reflection
        } else {
            reflections.insert(reflection, at: 0)
        }
        let data = try encoder.encode(reflections)
        try writeProtected(data: data, to: reflectionsURL)
    }

    public func fetchReflections() async throws -> [Reflection] {
        guard FileManager.default.fileExists(atPath: reflectionsURL.path) else { return [] }
        let data = try Data(contentsOf: reflectionsURL)
        return try decoder.decode([Reflection].self, from: data)
    }

    public func deleteReflection(id: UUID) async throws {
        var reflections = try await fetchReflections()
        reflections.removeAll { $0.id == id }
        let data = try encoder.encode(reflections)
        try writeProtected(data: data, to: reflectionsURL)
    }

    // MARK: Destroy

    public func destroyAll() throws {
        let files = [goalURL, habitsURL, milestonesURL, reflectionsURL]
        for url in files {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }
    }

    // MARK: Private

    private func writeProtected(data: Data, to url: URL) throws {
        try data.write(to: url, options: .completeFileProtection)
    }
}
