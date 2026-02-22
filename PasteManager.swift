import AppKit

class PasteManager {
    func paste(text: String) {
        // Save current pasteboard contents
        let pasteboard = NSPasteboard.general
        
        // It's robust to just clear and set strings. We'll simplify and just overwrite the clipboard.
        // Doing full backup/restore of NSPasteboard can be tricky, so for a simple app we overwrite it.
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Add a slight delay to allow clipboard to sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePasteCommand()
        }
    }
    
    private func simulatePasteCommand() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Command down
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true) // 0x37 is Command
        cmdDown?.flags = .maskCommand
        cmdDown?.post(tap: .cghidEventTap)
        
        // V down
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // 0x09 is 'v'
        vDown?.flags = .maskCommand
        vDown?.post(tap: .cghidEventTap)
        
        // V up
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        vUp?.post(tap: .cghidEventTap)
        
        // Command up
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        cmdUp?.post(tap: .cghidEventTap)
    }
}
