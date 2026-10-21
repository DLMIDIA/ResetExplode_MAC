import SwiftUI

@main
struct ResetExplodeApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 960, height: 640)
        
        MenuBarExtra("ResetExplode", systemImage: "bolt.shield.fill") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
