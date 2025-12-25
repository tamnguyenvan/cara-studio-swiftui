import SwiftUI
import UniformTypeIdentifiers

// MARK: - DATA MODELS

enum ProcessStatus {
    case processing
    case pending
    case completed
    case canceled
}

struct VideoItem: Identifiable {
    let id = UUID()
    var filename: String
    var size: String
    var originalRes: String
    var upscaleRes: String
    var status: ProcessStatus
    var progress: Double // 0.0 to 1.0
}

// MARK: - MAIN APP ENTRY POINT
@main
struct KaraStudioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
                .background(Color(nsColor: .windowBackgroundColor))
        }
        .windowStyle(.hiddenTitleBar) // Custom Header look
        .commands {
            SidebarCommands() // Disable sidebar toggle if not needed
        }
    }
}

// MARK: - MAIN CONTENT VIEW
struct ContentView: View {
    // State quản lý danh sách video
    @State private var videoItems: [VideoItem] = []
    
    // State quản lý hiển thị Settings
    @State private var showSettings: Bool = false
    
    // Giả lập trạng thái settings
    @State private var upscaleFactor: Int = 2 // 2 or 4
    @State private var outputDir: String = "/Users/osernme/Videos/Kara"
    
    var body: some View {
        ZStack {
            // Background chính
            Color(nsColor: .controlBackgroundColor).opacity(0.5).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. HEADER
                HStack {
                    // Traffic lights placeholder space (macOS tự vẽ nút đỏ/vàng/xanh, ta chỉ cần chừa chỗ)
                    Spacer().frame(width: 70)
                    
                    Spacer()
                    Text("Kara AI Studio")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary.opacity(0.8))
                    Spacer()
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                }
                .frame(height: 40)
                .background(Color(nsColor: .windowBackgroundColor))
                .overlay(Divider(), alignment: .bottom)
                
                // 2. MAIN CONTENT AREA
                if videoItems.isEmpty {
                    EmptyUploadView(onImport: simulateImport)
                } else {
                    ProcessingListView(items: $videoItems)
                }
            }
        }
        // Sheet Settings
        .sheet(isPresented: $showSettings) {
            SettingsView(upscaleFactor: $upscaleFactor, outputDir: $outputDir)
        }
    }
    
    // Hàm giả lập import để tạo UI giống ảnh mẫu
    func simulateImport() {
        withAnimation {
            videoItems = [
                VideoItem(filename: "Project_Shenanohah_4K.mov", size: "3.5 GB", originalRes: "3840x1220", upscaleRes: "7680x2440", status: .completed, progress: 1.0),
                VideoItem(filename: "Project_Forest_Drone.mov", size: "3.5 GB", originalRes: "3840x1220", upscaleRes: "", status: .processing, progress: 0.6),
                VideoItem(filename: "Timelapse_NYC_HD.mp4", size: "550 MB", originalRes: "1920x1080", upscaleRes: "", status: .pending, progress: 0.0),
                VideoItem(filename: "Happy_Dog_GoPro.avi", size: "1.2 GB", originalRes: "2704x1520", upscaleRes: "", status: .pending, progress: 0.0),
                VideoItem(filename: "Abstract_Render_Final.mkv", size: "2.1 GB", originalRes: "1920x1180", upscaleRes: "", status: .canceled, progress: 0.0)
            ]
        }
    }
}

// MARK: - SCREEN 1: UPLOAD AREA
struct EmptyUploadView: View {
    var onImport: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .foregroundColor(isHovering ? .blue : .gray.opacity(0.3))
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.2))
                
                VStack(spacing: 20) {
                    Image(systemName: "cloud.arrow.up")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.bottom, 10)
                    
                    Button(action: onImport) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Import Videos")
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                    .shadow(radius: 2)
                    
                    Text("or drag and drop your files here")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: 600, maxHeight: 400)
            .padding(40)
            .onDrop(of: [UTType.movie.identifier], isTargeted: $isHovering) { providers in
                onImport() // Trigger import on drop
                return true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - SCREEN 2: PROCESSING LIST
struct ProcessingListView: View {
    @Binding var items: [VideoItem]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach($items) { $item in
                    VideoRowView(item: $item)
                }
            }
            .padding(20)
        }
    }
}

struct VideoRowView: View {
    @Binding var item: VideoItem
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                Image(systemName: "photo") // Placeholder icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30)
                    .foregroundColor(.secondary)
                // In real app: use AVAssetImageGenerator for thumbnails
            }
            .frame(width: 80, height: 60)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.filename)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Text(item.size)
                    Text(item.originalRes)
                    if !item.upscaleRes.isEmpty {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                        Text(item.upscaleRes)
                            .foregroundColor(.blue)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // Progress Bar for processing items
                if item.status == .processing || item.status == .completed {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.gray.opacity(0.2))
                            Capsule()
                                .fill(item.status == .completed ? Color.green : Color.blue)
                                .frame(width: geo.size.width * CGFloat(item.progress))
                        }
                    }
                    .frame(height: 6)
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Status / Action Buttons
            HStack(spacing: 16) {
                switch item.status {
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    Button("Open") {
                        // Open file action
                    }
                    .buttonStyle(LinkButtonStyle()) // Custom style to look like pill
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    
                    Button(action: { deleteItem() }) {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                case .processing:
                    Text("Processing... \(Int(item.progress * 100))%")
                        .font(.callout)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                    
                    Button(action: { item.status = .canceled }) {
                        Image(systemName: "xmark.circle")
                            .font(.title2)
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    
                case .pending:
                    Text("Pending")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    Button(action: { deleteItem() }) {
                        Image(systemName: "xmark.circle")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    
                case .canceled:
                    Text("Cancel")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    Button(action: { deleteItem() }) {
                        Image(systemName: "xmark.circle")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    func deleteItem() {
        // Logic to remove item from list would go here
        // Note: Requires access to parent array logic
    }
}

// Custom button style helper
struct LinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

// MARK: - SETTINGS DIALOG
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var upscaleFactor: Int
    @Binding var outputDir: String
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            ZStack {
                Text("Settings")
                    .font(.headline)
                HStack {
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 10)
            
            Divider()
            
            // Upscale Factor
            VStack(alignment: .leading, spacing: 12) {
                Text("Default Upscale Factor")
                    .font(.system(size: 16, weight: .semibold))
                Text("Choose the default scaling factor for video upscaling")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    UpscaleOptionButton(
                        title: "2× Faster",
                        isSelected: upscaleFactor == 2,
                        action: { upscaleFactor = 2 }
                    )
                    
                    UpscaleOptionButton(
                        title: "4× Higher Quality",
                        isSelected: upscaleFactor == 4,
                        action: { upscaleFactor = 4 }
                    )
                }
                .padding(.top, 5)
            }
            
            // Output Directory
            VStack(alignment: .leading, spacing: 12) {
                Text("Output Directory")
                    .font(.system(size: 16, weight: .semibold))
                
                HStack {
                    Text(outputDir)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onTapGesture {
                    // Open NSOpenPanel here normally
                }
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 450, height: 350)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct UpscaleOptionButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.15))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(isSelected ? 0 : 0), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
