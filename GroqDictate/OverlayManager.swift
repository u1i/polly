import SwiftUI
import AppKit

class OverlayManager {
    static let shared = OverlayManager()
    private var overlayWindow: NSWindow?
    
    func show() {
        if overlayWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 220, height: 60),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .floating // or .screenSaver for even higher
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            
            let host = NSHostingController(rootView: OverlayView())
            window.contentView = host.view
            
            if let screen = NSScreen.main {
                let rect = screen.visibleFrame
                let x = rect.midX - 110
                let y = rect.minY + 60 // Bottom center
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
            overlayWindow = window
        }
        
        // Temporarily make sure we don't become the active app
        // LSUIElement usually prevents it, but orderFront can sometimes trigger it
        overlayWindow?.orderFrontRegardless()
    }
    
    func hide() {
        overlayWindow?.orderOut(nil)
    }
}

struct OverlayView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mic.fill")
                .foregroundColor(.red)
                .font(.title3)
            Text("Recording Dictation...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Capsule().fill(Color.black.opacity(0.8)))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}
