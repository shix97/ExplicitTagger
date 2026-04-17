// AdvisoryTaggerApp.swift
// App entry point.  Sets up a single fixed-size window with dark Aqua chrome.

import SwiftUI

@main
struct AdvisoryTaggerApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Advisory Tagger", id: "main") {
            ContentView()
        }
        // Lock the window to exactly the content size — no resizing.
        .windowResizability(.contentSize)
    }
}

// MARK: - App delegate

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Force dark Aqua so the window chrome matches our dark UI.
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }

    // Quit when the last window is closed (standard utility-app behaviour).
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
