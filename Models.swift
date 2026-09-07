import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var createdAt: Date
    var tasks: [TaskItem]?

    init(name: String, createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.createdAt = createdAt
        self.tasks = []
    }
}

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var priority: Int // 1: Low, 2: Medium, 3: High
    var status: String // "Pending", "In Progress", "Completed"
    var timeSpent: TimeInterval
    var parentTask: TaskItem?
    var subTasks: [TaskItem]?
    var completionVelocity: Double? // Tasks completed per hour
    var lastCompleted: Date?



    init(title: String, priority: Int = 2, status: String = "Pending", timeSpent: TimeInterval = 0, taskDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.priority = priority
        self.status = status
        self.timeSpent = timeSpent
        self.subTasks = []
        self.taskDate = taskDate
    }
}

@Model
final class JournalEntry {
    var id: UUID
    var content: String
    var timestamp: Date
    var isArchived: Bool
    var relatedTask: TaskItem?

    init(content: String, timestamp: Date = .now, isArchived: Bool = false) {
        self.id = UUID()
        self.content = content
        self.timestamp = timestamp
        self.isArchived = isArchived
    }
}

@Model
final class UserSettings {
    var isPro: Bool
    var preferredFlow: String // "50/10", "90/15"
    
    init(isPro: Bool = false, preferredFlow: String = "50/10") {
        self.isPro = isPro
        self.preferredFlow = preferredFlow
    }
}
