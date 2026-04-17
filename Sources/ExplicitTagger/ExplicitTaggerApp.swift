// ExplicitTaggerApp.swift

import SwiftUI
import CoreText

@main
struct ExplicitTaggerApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("ExplicitTagger", id: "main") {
            ContentView()
        }
        .windowResizability(.contentSize)
        .commands {
            // Replace the default "About AppName" item with our custom About window.
            CommandGroup(replacing: .appInfo) {
                Button("About ExplicitTagger") {
                    NSApp.sendAction(#selector(AppDelegate.showAboutWindow), to: nil, from: nil)
                }
            }
        }
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var aboutWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .aqua)
        registerBundledFonts()
    }

    /// Register custom fonts from the app bundle so SwiftUI can use them by name.
    private func registerBundledFonts() {
        let names = ["AppleGaramond-Light"]
        for name in names {
            // Try Bundle.module first (Swift Package resources), then Bundle.main (.app)
            let url = Bundle.module.url(forResource: name, withExtension: "ttf")
                   ?? Bundle.main.url(forResource: name, withExtension: "ttf")
            if let url {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @objc func showAboutWindow() {
        if aboutWindow == nil {
            let hosting = NSHostingController(rootView: AboutView())
            let win = NSWindow(contentViewController: hosting)
            win.title = "About ExplicitTagger"
            win.styleMask = [.titled, .closable]
            win.isReleasedWhenClosed = false
            win.center()
            aboutWindow = win
        }
        aboutWindow?.makeKeyAndOrderFront(nil)
    }
}
