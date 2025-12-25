//
//  KaraStudioApp.swift
//  Kara AI Studio
//

import SwiftUI

@main
struct LuminaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
        }
        .windowStyle(.hiddenTitleBar) // Ẩn title bar mặc định để tạo hiệu ứng full window
        .commands {
            SidebarCommands() // Hỗ trợ ẩn/hiện sidebar
        }
    }
}

// Helper để tạo hiệu ứng nền mờ (Blur) chuẩn macOS nếu cần thiết cho các component con
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
