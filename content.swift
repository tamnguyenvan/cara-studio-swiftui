import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - Models & Data

enum Tab: String, CaseIterable {
    case library = "Library"
    case queue = "Queue"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .library: return "square.grid.2x2"
        case .queue: return "list.bullet"
        case .settings: return "gearshape"
        }
    }
}

enum ProcessStatus: String {
    case processing = "PROCESSING"
    case paused = "PAUSED"
    case stopped = "STOPPED"
    case completed = "DONE"
    case waiting = "WAITING"
    
    var color: Color {
        switch self {
        case .processing: return .blue
        case .paused: return .orange
        case .stopped: return .red
        case .completed: return .green
        case .waiting: return .gray
        }
    }
}

struct VideoItem: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var progress: Double // 0.0 to 1.0
    var status: ProcessStatus
    var thumbnailName: String // Giả lập tên ảnh
}

// MARK: - ViewModel

class AppViewModel: ObservableObject {
    @Published var currentTab: Tab = .library
    @Published var queueItems: [VideoItem] = []
    
    // Settings
    @Published var scaleMagnification: Int = 2 // 2x or 4x
    @Published var hardwareAcceleration: Bool = true
    @Published var autoSaveToDesktop: Bool = false
    
    // Batch Processing logic giả lập
    func addFilesToQueue() {
        let newVideo = VideoItem(name: "output_\(Int.random(in: 1...100)).mp4", progress: 0.0, status: .processing, thumbnailName: "photo")
        queueItems.append(newVideo)
        
        // Chuyển sang tab Queue tự động
        currentTab = .queue
        startSimulation(for: newVideo.id)
    }
    
    func startSimulation(for id: UUID) {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if let index = self.queueItems.firstIndex(where: { $0.id == id }) {
                if self.queueItems[index].status == .processing {
                    self.queueItems[index].progress += 0.05
                    if self.queueItems[index].progress >= 1.0 {
                        self.queueItems[index].progress = 1.0
                        self.queueItems[index].status = .completed
                        timer.invalidate()
                    }
                } else if self.queueItems[index].status == .stopped || self.queueItems[index].status == .completed {
                    timer.invalidate()
                }
            } else {
                timer.invalidate()
            }
        }
    }
    
    func updateStatus(_ item: VideoItem, to status: ProcessStatus) {
        if let index = queueItems.firstIndex(where: { $0.id == item.id }) {
            queueItems[index].status = status
            // Nếu resume lại
            if status == .processing {
                startSimulation(for: item.id)
            }
        }
    }
    
    func remove(_ item: VideoItem) {
        queueItems.removeAll(where: { $0.id == item.id })
    }
    
    func clearAll() {
        queueItems.removeAll()
    }
    
    var processingCount: Int {
        queueItems.filter { $0.status == .processing }.count
    }
}

// MARK: - Main View

struct ContentView: View {
    @StateObject var viewModel = AppViewModel()
    
    var body: some View {
        NavigationSplitView {
            SidebarView(currentTab: $viewModel.currentTab, processingCount: viewModel.processingCount)
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
                .background(.ultraThinMaterial) // Visual Effect cho Sidebar
        } detail: {
            Group {
                switch viewModel.currentTab {
                case .library:
                    LibraryView(viewModel: viewModel)
                case .queue:
                    QueueView(viewModel: viewModel)
                case .settings:
                    SettingsView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var currentTab: Tab
    var processingCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Traffic Light spacer
            Color.clear.frame(height: 30)
            
            // App Header
            HStack {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Lumina")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            
            // Navigation Links
            VStack(spacing: 4) {
                SidebarButton(title: "Library", icon: "square.grid.2x2", isSelected: currentTab == .library) {
                    currentTab = .library
                }
                
                SidebarButton(title: "Queue", icon: "list.bullet", isSelected: currentTab == .queue, badge: processingCount > 0 ? processingCount : nil) {
                    currentTab = .queue
                }
                
                SidebarButton(title: "Settings", icon: "gearshape", isSelected: currentTab == .settings) {
                    currentTab = .settings
                }
            }
            .padding(.horizontal, 10)
            
            Spacer()
            
            // Engine Status Footer
            VStack(alignment: .leading, spacing: 4) {
                Text("ENGINE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Text("Simulated Core")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(10)
            .padding(16)
        }
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var badge: Int? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                    .fontWeight(isSelected ? .semibold : .regular)
                Spacer()
                
                if let badge = badge {
                    Text("\(badge)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.primary.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

// MARK: - Library View

struct LibraryView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(title: "Library")
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .foregroundColor(isTargeted ? .blue : .gray.opacity(0.3))
                
                VStack(spacing: 20) {
                    Image(systemName: "icloud.and.arrow.up")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(20)
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Text("Import Media")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Drag files here to start\nhigh-fidelity AI enhancement.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        viewModel.addFilesToQueue()
                    }) {
                        Text("Choose Files...")
                            .fontWeight(.medium)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(50)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                // Giả lập xử lý drop file
                viewModel.addFilesToQueue()
                return true
            }
        }
    }
}

// MARK: - Queue View

struct QueueView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(title: "Active Queue") {
                if !viewModel.queueItems.isEmpty {
                    Button("Clear All Items") {
                        viewModel.clearAll()
                    }
                    .buttonStyle(.link)
                }
            }
            
            if viewModel.queueItems.isEmpty {
                VStack {
                    Spacer()
                    Text("No items currently upscaling.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.queueItems) { item in
                            QueueItemRow(item: item, viewModel: viewModel)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct QueueItemRow: View {
    let item: VideoItem
    @ObservedObject var viewModel: AppViewModel
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            ZStack {
                Rectangle().fill(Color.black.opacity(0.2))
                Image(systemName: "film")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30)
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(width: 80, height: 45)
            .cornerRadius(6)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.name)
                        .fontWeight(.medium)
                    Spacer()
                    
                    // Status Badge
                    if item.status != .completed {
                        HStack(spacing: 4) {
                            if item.status == .processing {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .frame(width: 10, height: 10)
                            }
                            Text(item.status.rawValue)
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.status.color.opacity(0.1))
                        .foregroundColor(item.status.color)
                        .cornerRadius(4)
                    } else {
                         Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                // Progress Bar
                ProgressView(value: item.progress)
                    .progressViewStyle(.linear)
                    .tint(.blue)
                
                HStack {
                    Text(item.status == .completed ? "Completed" : "Rendering • \(Int(item.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Actions on Hover
                    if isHovering {
                        HStack(spacing: 12) {
                            if item.status == .processing {
                                Button(action: { viewModel.updateStatus(item, to: .paused) }) {
                                    Image(systemName: "pause.fill")
                                }
                            } else if item.status == .paused {
                                Button(action: { viewModel.updateStatus(item, to: .processing) }) {
                                    Image(systemName: "play.fill")
                                }
                            }
                            
                            Button(action: { viewModel.addFilesToQueue() }) { // Retry Logic giả
                                Image(systemName: "arrow.clockwise")
                            }
                            .help("Retry")
                            
                            Button(action: { viewModel.remove(item) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hover
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(title: "Global Settings")
            
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Scale Magnification")
                                .fontWeight(.medium)
                        }
                        .font(.headline)
                        
                        Text("Define the default enhancement resolution for new projects.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $viewModel.scaleMagnification) {
                            Text("2x").tag(2)
                            Text("4x").tag(4)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(maxWidth: 300)
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    Toggle(isOn: $viewModel.hardwareAcceleration) {
                        VStack(alignment: .leading) {
                            Text("Hardware Acceleration")
                                .fontWeight(.medium)
                            Text("Batch upscale up to 4 videos at once utilizing Neural Engine.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .padding(.vertical, 8)
                    
                    Toggle(isOn: $viewModel.autoSaveToDesktop) {
                        VStack(alignment: .leading) {
                            Text("Auto-Save to Desktop")
                                .fontWeight(.medium)
                            Text("Export results automatically on completion.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .padding(.vertical, 8)
                }
            }
            .formStyle(.grouped)
            .padding()
        }
    }
}

// MARK: - Common Components

struct HeaderView<Content: View>: View {
    let title: String
    let trailing: Content
    
    init(title: String, @ViewBuilder trailing: () -> Content = { EmptyView() }) {
        self.title = title
        self.trailing = trailing()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                trailing
            }
            .padding(20)
            
            Divider()
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
