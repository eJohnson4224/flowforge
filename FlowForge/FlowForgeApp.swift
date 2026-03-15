//
//  FlowForgeApp.swift
//  FlowForge
//
//  Created by Eli j on 04.01.26.
//

import SwiftUI

@main
struct FlowForgeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 700)
        .commands {
            // macOS menu bar commands
            CommandGroup(replacing: .newItem) {
                // Remove "New" menu item (not applicable)
            }

            CommandGroup(after: .newItem) {
                Button("Rescan Folders") {
                    NotificationCenter.default.post(name: .rescanFolders, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command])

                Divider()
            }

            // Settings in standard macOS location
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
        }

        #if os(macOS)
        // macOS-specific settings window
        Settings {
            SettingsView()
                .frame(width: 600, height: 500)
        }
        #endif
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let rescanFolders = Notification.Name("rescanFolders")
    static let openSettings = Notification.Name("openSettings")
}
