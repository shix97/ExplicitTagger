// ContentView.swift
// UI rebuilt from mockup: chrome top/bottom, cream mode panel,
// light-blue-grey main area, glossy pill buttons, dashed drop zone.

import SwiftUI
import UniformTypeIdentifiers
import AppKit

// MARK: - Tag mode

enum TagMode: CaseIterable, Identifiable {
    case explicit, remove, clean   // left → right button order

    var id: Self { self }

    /// Text shown on the pill button.
    var buttonLabel: String {
        switch self {
        case .explicit: return "Explicit"
        case .remove:   return "Remove Tag"
        case .clean:    return "Clean"
        }
    }

    /// Text shown in the "Current Mode:" panel.
    /// Acceptable values: Explicit | Clean | No Advisory Tag
    var modeLabel: String {
        switch self {
        case .explicit: return "Explicit"
        case .clean:    return "Clean"
        case .remove:   return "No Advisory Tag"
        }
    }

    var advisoryValue: UInt8 {
        switch self {
        case .explicit: return 1
        case .clean:    return 2
        case .remove:   return 0
        }
    }
}

// MARK: - Colour palette (sampled from mockup)

extension Color {
    /// Initialise from a 6-digit hex string, e.g. "#bfc8d2".
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        self.init(
            red:   Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8)  & 0xFF) / 255,
            blue:  Double( v        & 0xFF) / 255
        )
    }

    // ── Chrome gradient stops ─────────────────────────────────────────────────
    static let mkChromeTop = Color(hex: "#c4c6c8")   // lighter at the very top
    static let mkChromeBot = Color(hex: "#a8aaae")   // darker at the bottom edge

    // ── Bottom bar gradient stops (slightly inverted — lighter at bottom) ─────
    static let mkBarTop    = Color(hex: "#a0a2a6")
    static let mkBarBot    = Color(hex: "#b8babe")

    // ── Main blue-grey content area ───────────────────────────────────────────
    static let mkMainBg    = Color(hex: "#bdc7d1")

    // ── Cream "Current Mode" panel ────────────────────────────────────────────
    static let mkCream     = Color(hex: "#e6eac8")
    static let mkCreamBdr  = Color(hex: "#888888")
    static let mkPanelTxt  = Color(hex: "#2a2a2a")

    // ── "Select Mode:" heading ────────────────────────────────────────────────
    static let mkHeading   = Color(hex: "#3a3a50")

    // ── Drop-zone ─────────────────────────────────────────────────────────────
    static let mkDashBdr   = Color(hex: "#8a8a96")
    static let mkDropTxt   = Color(hex: "#8a8a9a")

    // ── Explicit button (red — lightened one step) ───────────────────────────
    static let mkRedTop    = Color(hex: "#e85050")
    static let mkRedBot    = Color(hex: "#c03030")

    // ── Remove Tag button (silver-grey) ──────────────────────────────────────
    static let mkGrayTop   = Color(hex: "#dcdcdc")
    static let mkGrayBot   = Color(hex: "#a4a4a4")

    // ── Clean button (lime-green — lightened one step) ────────────────────────
    static let mkGreenTop  = Color(hex: "#a8d040")
    static let mkGreenBot  = Color(hex: "#78a020")

    // ── "+" icon on drop zone ─────────────────────────────────────────────────
    static let mkPlusTop   = Color(hex: "#38802e")
    static let mkPlusBot   = Color(hex: "#1a5010")

    // ── Button label text ─────────────────────────────────────────────────────
    static let mkBtnTxt    = Color(hex: "#2a2a2a")
}

// MARK: - Icon loader (shared with AboutView)

/// Tries Bundle.module (SPM resources) then Bundle.main (built .app).
func loadBundledIcon() -> NSImage? {
    if let url = Bundle.module.url(forResource: "icon", withExtension: "png"),
       let img = NSImage(contentsOf: url) { return img }
    if let url = Bundle.main.url(forResource:  "icon", withExtension: "png"),
       let img = NSImage(contentsOf: url) { return img }
    return nil
}

// MARK: - Root view

struct ContentView: View {

    @State private var mode:         TagMode = .explicit
    /// What the "Current Mode:" panel shows right now.
    /// Allowed persistent values: Explicit | Clean | No Advisory Tag
    /// Transient flash values: Completed | Error
    @State private var displayLabel: String  = "Explicit"
    @State private var isDragging:   Bool    = false
    @State private var flashTask:    Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            modePanel       // cream inset box showing current mode
            mainArea        // blue-grey section: heading + buttons + drop zone
            bottomBar       // grey bar with version string
        }
        .frame(width: 520, height: 520)
    }

    // ── Mode panel ────────────────────────────────────────────────────────────

    private var modePanel: some View {
        ZStack {
            LinearGradient(
                colors: [.mkChromeTop, .mkChromeBot],
                startPoint: .top, endPoint: .bottom
            )

            RoundedRectangle(cornerRadius: 7)
                .fill(Color.mkCream)
                // Subtle inner shadow: faint dark overlay at the bottom edge
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.06)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .frame(height: 18)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(Color.mkCreamBdr, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 14)
                .padding(.vertical,   10)
                .overlay(
                    VStack(spacing: 3) {
                        Text("Current Mode:")
                            .font(.custom("LucidaGrande-Bold", size: 13))
                            .foregroundStyle(Color.mkPanelTxt)
                        Text(displayLabel)
                            .font(.custom("LucidaGrande-Bold", size: 13))
                            .foregroundStyle(Color.mkPanelTxt)
                            .animation(.easeInOut(duration: 0.15), value: displayLabel)
                    }
                )
        }
        .frame(height: 78)
    }

    // ── Main blue-grey area ───────────────────────────────────────────────────

    private var mainArea: some View {
        VStack(spacing: 0) {

            // Large serif heading — Apple Garamond Light
            Text("Select Mode:")
                .font(.custom("AppleGaramondLight", size: 40))
                .foregroundStyle(Color.mkHeading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 22)
                .padding(.bottom, 18)

            // Pill buttons — left: Explicit  |  middle: Remove Tag  |  right: Clean
            HStack(spacing: 14) {
                PillButton(
                    label: "Explicit",
                    topColor: .mkRedTop,   botColor: .mkRedBot,
                    isSelected: mode == .explicit
                ) { selectMode(.explicit) }

                PillButton(
                    label: "Remove Tag",
                    topColor: .mkGrayTop,  botColor: .mkGrayBot,
                    isSelected: mode == .remove
                ) { selectMode(.remove) }

                PillButton(
                    label: "Clean",
                    topColor: .mkGreenTop, botColor: .mkGreenBot,
                    isSelected: mode == .clean
                ) { selectMode(.clean) }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 20)

            // Drop zone
            dropZone
                .padding(.horizontal, 14)
                .padding(.bottom, 18)
        }
        .frame(maxHeight: .infinity)
        .background(Color.mkMainBg)
    }

    // ── Drop zone ─────────────────────────────────────────────────────────────

    private var dropZone: some View {
        ZStack {
            // Fill (slightly distinct from the main bg for depth)
            RoundedRectangle(cornerRadius: 10)
                .fill(isDragging
                      ? Color.mkMainBg.opacity(0.55)
                      : Color.mkMainBg.opacity(0.38))

            // Dashed border — thicker / greener while dragging
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isDragging ? Color.mkPlusTop : Color.mkDashBdr,
                    style: StrokeStyle(lineWidth: 2, dash: [9, 7])
                )

            // Centre content
            VStack(spacing: 10) {
                Text("Drag & Drop an .m4a or .alac File")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.mkDropTxt)

                // Green "+" badge
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.mkPlusTop, .mkPlusBot],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(width: 30, height: 30)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        // ── Accept file drops from Finder ──────────────────────────────────────
        .onDrop(of: [UTType.fileURL], isTargeted: $isDragging) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadTransferable(type: URL.self) { result in
                DispatchQueue.main.async {
                    if case .success(let url) = result { processFile(url) }
                }
            }
            return true
        }
        // ── Click opens the system file picker ────────────────────────────────
        .onTapGesture { openFilePicker() }
        .cursor(.pointingHand)
        .animation(.easeInOut(duration: 0.12), value: isDragging)
    }

    // ── Bottom bar ────────────────────────────────────────────────────────────

    private var bottomBar: some View {
        ZStack {
            LinearGradient(
                colors: [.mkBarTop, .mkBarBot],
                startPoint: .top, endPoint: .bottom
            )
            Text("Version 1.1 by Shix")
                .font(.custom("LucidaGrande-Bold", size: 9.5))
                .foregroundStyle(Color(hex: "#1a1a1a"))
        }
        .frame(height: 26)
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private func selectMode(_ newMode: TagMode) {
        mode = newMode
        flashTask?.cancel()
        displayLabel = newMode.modeLabel
    }

    private static let supportedExtensions: Set<String> = ["m4a", "alac"]

    private func processFile(_ url: URL) {
        guard Self.supportedExtensions.contains(url.pathExtension.lowercased()) else {
            flash("Error")
            return
        }
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            try MP4Tagger.setAdvisory(mode.advisoryValue, fileURL: url)
            flash("Completed", thenRestore: mode.modeLabel)
        } catch {
            flash("Error")
        }
    }

    /// Shows `label` for 1 second, then restores the mode label (or the mode's
    /// current label if `thenRestore` is nil).
    private func flash(_ label: String, thenRestore restore: String? = nil) {
        flashTask?.cancel()
        displayLabel = label
        let restoreLabel = restore ?? mode.modeLabel
        flashTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            await MainActor.run { displayLabel = restoreLabel }
        }
    }

    /// Opens an NSOpenPanel filtered to .m4a and .alac files.
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.title               = "Select an M4A or ALAC File"
        panel.allowedContentTypes = ["m4a", "alac"].compactMap { UTType(filenameExtension: $0) }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories    = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        processFile(url)
    }
}

// MARK: - Glossy pill button

/// A capsule-shaped button with a two-stop gradient, top gloss highlight,
/// drop shadow, and a visually darker press state tracked via ButtonStyle.
struct PillButton: View {

    let label:      String
    let topColor:   Color
    let botColor:   Color
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(label, action: action)
            .buttonStyle(PillStyle(
                topColor: topColor, botColor: botColor, isSelected: isSelected
            ))
            // Restrict hit-testing to the capsule shape (not its bounding rect).
            .contentShape(Capsule())
            .cursor(.pointingHand)
    }
}

private struct PillStyle: ButtonStyle {

    let topColor:   Color
    let botColor:   Color
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        Capsule()
            // ── Main gradient ──────────────────────────────────────────────
            // Pressed: shift the whole gradient darker and invert slightly
            .fill(LinearGradient(
                stops: pressed
                    ? [
                        .init(color: botColor.opacity(0.82), location: 0.00),
                        .init(color: topColor.opacity(0.70), location: 1.00)
                      ]
                    : [
                        .init(color: topColor,               location: 0.00),
                        .init(color: botColor,               location: 1.00)
                      ],
                startPoint: .top, endPoint: .bottom
            ))
            // ── Aqua gloss highlight (top ~50%) ────────────────────────────
            .overlay(alignment: .top) {
                Capsule()
                    .fill(LinearGradient(
                        stops: pressed
                            ? [
                                .init(color: .white.opacity(0.20), location: 0.00),
                                .init(color: .white.opacity(0.08), location: 0.45),
                                .init(color: .clear,               location: 0.46)
                              ]
                            : [
                                .init(color: .white.opacity(0.90), location: 0.00),
                                .init(color: .white.opacity(0.55), location: 0.30),
                                .init(color: .white.opacity(0.08), location: 0.50),
                                .init(color: .clear,               location: 0.51)
                              ],
                        startPoint: .top, endPoint: .bottom
                    ))
            }
            // ── Bottom-edge lift shimmer ───────────────────────────────────
            .overlay(alignment: .bottom) {
                if !pressed {
                    Capsule()
                        .fill(LinearGradient(
                            colors: [.clear, .white.opacity(0.18)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(height: 10)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 2)
                }
            }
            // ── Top inset shadow when pressed ──────────────────────────────
            .overlay(alignment: .top) {
                if pressed {
                    Capsule()
                        .fill(LinearGradient(
                            colors: [.black.opacity(0.22), .clear],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(height: 8)
                        .padding(.horizontal, 4)
                        .padding(.top, 1)
                }
            }
            // ── Label ─────────────────────────────────────────────────────
            .overlay {
                configuration.label
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.mkBtnTxt)
                    .shadow(color: .white.opacity(0.35), radius: 0, x: 0, y: 1)
            }
            // ── Selection ring ────────────────────────────────────────────
            .overlay {
                if isSelected {
                    Capsule()
                        .strokeBorder(.white.opacity(0.65), lineWidth: 2.5)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 38, maxHeight: 38)
            .shadow(
                color: pressed ? .clear : .black.opacity(0.32),
                radius: pressed ? 0 : 3,
                x: 0,
                y: pressed ? 0 : 2
            )
            .animation(.easeInOut(duration: 0.07), value: pressed)
    }
}

// MARK: - Cursor helper

private extension View {
    func cursor(_ c: NSCursor) -> some View {
        onHover { inside in if inside { c.push() } else { NSCursor.pop() } }
    }
}
