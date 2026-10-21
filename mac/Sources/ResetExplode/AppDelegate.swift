import AppKit
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static var shared: AppDelegate?
    
    public var statusItem: NSStatusItem?
    public var popover: NSPopover?
    private var timer: Timer?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        setupStatusItem()
        NSApp.setActivationPolicy(.regular)
    }
    
    public func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bolt.shield.fill", accessibilityDescription: "ResetExplode")
            button.imagePosition = .imageLeading
            button.title = " --%"
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
        }
        
        let pop = NSPopover()
        pop.contentSize = NSSize(width: 320, height: 500)
        pop.behavior = .transient
        pop.contentViewController = NSHostingController(rootView: MenuBarView())
        self.popover = pop
        
        startMonitoringTimer()
    }
    
    @objc public func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let popover = self.popover else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Permite que o app continue rodando silenciosamente na Barra de Menus
        return false
    }
    
    public func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        
        var found = false
        for window in NSApp.windows {
            // Janela principal (não painel/popover)
            if !(window is NSPanel) && window.canBecomeMain {
                window.makeKeyAndOrderFront(nil)
                found = true
                break
            }
        }
        
        if !found {
            // Se fechada, reabre
            if let url = URL(string: "resetexplode://main") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    private func startMonitoringTimer() {
        updateStatusBarText()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateStatusBarText()
            }
        }
    }
    
    private func updateStatusBarText() {
        let ram = HardwareService.shared.getRAMInfo()
        let net = NetworkService.shared.getCurrentStats()
        
        let speedStr: String
        if net.downloadSpeedKBps >= 1024.0 {
            speedStr = String(format: "%.1fM", net.downloadSpeedKBps / 1024.0)
        } else {
            speedStr = String(format: "%.0fK", net.downloadSpeedKBps)
        }
        
        guard let button = self.statusItem?.button else { return }
        button.title = String(format: " %.0f%% | ↓%@", ram.usagePercent, speedStr)
    }
}
