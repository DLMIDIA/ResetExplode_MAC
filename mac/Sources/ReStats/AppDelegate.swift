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
            if MenuBarSettingsService.shared.showIcon {
                button.image = NSImage(systemSymbolName: "bolt.shield.fill", accessibilityDescription: "ReStats")
                button.imagePosition = .imageLeading
            } else {
                button.image = nil
            }
            button.title = " --%"
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
        }
        
        let pop = NSPopover()
        pop.contentSize = NSSize(width: 320, height: 580)
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
        // Permite que o app continue rodando silenciosamente na Barra de Menus 24/7
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
            if let url = URL(string: "restats://main") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    public func refreshStatusBarNow() {
        updateStatusBarText()
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
        let cpu = HardwareService.shared.getCPUInfo()
        let ram = HardwareService.shared.getRAMInfo()
        let net = NetworkService.shared.getCurrentStats()
        let battery = HardwareService.shared.getBatteryInfo()
        let thermal = ThermalService.shared.getThermalInfo()
        let volumes = DiskVolumeService.shared.listMountedVolumes()
        
        guard let button = self.statusItem?.button else { return }
        
        if MenuBarSettingsService.shared.showIcon {
            button.image = NSImage(systemSymbolName: "bolt.shield.fill", accessibilityDescription: "ReStats")
            button.imagePosition = .imageLeading
        } else {
            button.image = nil
        }
        
        button.title = MenuBarSettingsService.shared.formattedStatusText(
            cpu: cpu.overallUsage,
            ram: ram.usagePercent,
            downloadKBps: net.downloadSpeedKBps,
            batteryPct: battery.percentage,
            socTemp: thermal.socTemperatureC,
            volumes: volumes
        )
    }
}
