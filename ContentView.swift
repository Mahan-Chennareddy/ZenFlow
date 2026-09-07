import SwiftUI
import SwiftData
import AVFoundation
import LocalAuthentication

// MARK: - Models (Referencing Models.swift logic)
// Note: SwiftData models are defined in Models.swift

// MARK: - View Model for Timer Logic
@MainActor
class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval = 3000
    @Published var isRunning = false
    @Published var currentFlow: String = "50/10"
    
    private var cancellables = Set<AnyCancellable>()
    private let audioManager = AudioManager()
    
    init() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.isRunning = false
                }
            }
            .store(in: &cancellables)
    }
    
    func toggleTimer() {
        isRunning.toggle()
    }
    
    func playAmbientSound(named name: String) {
        audioManager.playAmbientSound(named: name)
    }
}


// MARK: - UI Components

struct ArchitectView: View {
    @Query private var projects: [Project]
    @Environment(\.modelContext) private var modelContext
    @State private var newProjectName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(projects) { project in
                    NavigationLink(destination: TaskTreeView(project: project)) {
                        VStack(alignment: .leading) {
                            Text(project.name).font(.headline)
                            Text("\(project.tasks?.count ?? 0) Tasks").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                Button(action: addProject) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func addProject() {
        let project = Project(name: newProjectName.isEmpty ? "New Project" : newProjectName)
        modelContext.insert(project)
        newProjectName = ""
    }
}

struct TaskTreeView: View {
    var project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var newTaskTitle = ""
    @State private var isLoading = false

    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading Tasks...")
            } else {
                ForEach(project.tasks ?? []) { task in
                    RecursiveTaskView(task: task)
                }
            }
            
            Section("Quick Add") {
                HStack {
                    TextField("Micro-action...", text: $newTaskTitle)
                    Button("Add") {
                        let newTask = TaskItem(title: newTaskTitle)
                        newTask.project = project
                        project.tasks?.append(newTask)
                        modelContext.insert(newTask)
                        newTaskTitle = ""
                    }
                    .disabled(newTaskTitle.isEmpty)
                }
            }
        }
        .navigationTitle(project.name)
        .onAppear {
            // Placeholder for lazy loading logic
            // In a full implementation, this would trigger a fetch with offsets
        }
    }
}

struct RecursiveTaskView: View {
    var task: TaskItem
    @State private var isExpanded = true
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    .onTapGesture { withAnimation { isExpanded.toggle() } }
                
                Text(task.title)
                Spacer()
                Text(task.status).font(.caption).padding(4).background(Color.gray.opacity(0.2)).cornerRadius(4)
            }
            
            if isExpanded {
                ForEach(task.subTasks ?? []) { subTask in
                    RecursiveTaskView(task: subTask)
                        .padding(.leading, 20)
                }
            }
        }
    }
}

struct TimerView: View {
@StateObject private var timerManager = TimerManager()
    @State private var interruptNote = ""
    @State private var entries: [JournalEntry] = []
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Timer Display
                VStack {
                    Text(formatTime(timerManager.timeRemaining))
                        .font(.system(size: 80, weight: .thin, design: .monospaced))
                        .foregroundStyle(.primary)
                    
                    Button(action: { 
                        timerManager.toggleTimer()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        Image(systemName: timerManager.isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundStyle(.blue)
                    }
                }
                .padding()
                .matchedGeometryEffect(id: "timerDisplay")

                // Interrupt Journal
                VStack(alignment: .leading) {
                    Text("Interrupt Journal").font(.headline)
                    TextEditor(text: $interruptNote)
                        .frame(height: 150)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                    
                    Button("Log Interrupt") {
                        let entry = JournalEntry(content: interruptNote)
                        modelContext.insert(entry)
                        interruptNote = ""
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding()

                // Quick Actions
                HStack {
                    Button("Rain") { 
                        timerManager.playAmbientSound(named: "rain")
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }
                    Button("White Noise") { 
                        timerManager.playAmbientSound(named: "white_noise")
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }
                }
            }
            .navigationTitle("Flow State")
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                timerManager.isRunning = false
            } else if newPhase == .active {
                // Logic to resume if it was running could go here
            }
        }
    }
    }

    func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct TrendsView: View {
    @Query private var projects: [Project]
    @Query private var tasks: [TaskItem]

    var completionVelocity: Double {
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let completedTasks = tasks.filter { 
            $0.status == "Completed" && 
            (taskDate ?? Date()) >= weekAgo 
        }
        return Double(completedTasks.count) / 7.0
    }


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Text("Performance Trends").font(.largeTitle).bold()
                    Text("Completion Velocity: \(Int(completionVelocity)) tasks/week")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom)

                    Chart {
                        ForEach(tasks.sorted(by: { $0.taskDate ?? Date() < $1.taskDate ?? Date() })) { task in
                            BarMark(
                                x: .value("Date", task.taskDate?.formatted(.dateTime.day()) ?? "Unknown") {
                                    _ in "Day"
                                },
                                y: .value("Time", task.timeSpent)
                            )
                            .foregroundStyle(Color.blue)
                        }
                    }
                    .frame(height: 300)
                    .padding()
                }
            }
            .navigationTitle("Trends")
        }
            }
            .navigationTitle("Trends")
        }
    }
}


struct ZenFlowApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ArchitectView().tabItem { Label("Architect", systemImage: "building.2") }
                TimerView().tabItem { Label("Flow", systemImage: "timer") }
                TrendsView().tabItem { Label("Trends", systemImage: "chart.bar") }
            }
            .modelContainer(for: [Project.self, TaskItem.self, JournalEntry.self, UserSettings.self])
        }
    }
}
