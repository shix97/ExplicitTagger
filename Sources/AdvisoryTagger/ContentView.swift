// ContentView.swift
// iTunes 7-inspired dark UI with three mode buttons and a drag-and-drop zone.

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Tag mode

enum TagMode: CaseIterable, Identifiable {
    case explicit, clean, remove

    var id: Self { self }

    var label: String {
        switch self {
        case .explicit: return "🔞  Explicit"
        case .clean:    return "✓  Clean"
        case .remove:   return "✕  Remove Tag"
        }
    }

    var displayName: String {
        switch self {
        case .explicit: return "Explicit"
        case .clean:    return "Clean"
        case .remove:   return "Remove Tag"
        }
    }

    var successIcon: String {
        switch self {
        case .explicit: return "🔞"
        case .clean:    return "✓"
        case .remove:   return "○"
        }
    }

    var advisoryValue: UInt8 {
        switch self {
        case .explicit: return 1
        case .clean:    return 2
        case .remove:   return 0
        }
    }

    // Button colours
    var colorNormal:   Color { palette.normal   }
    var colorHover:    Color { palette.hover     }
    var colorSelected: Color { palette.selected  }

    private var palette: (normal: Color, hover: Color, selected: Color) {
        switch self {
        case .explicit:
            return (
                Color(red: 0.55, green: 0.10, blue: 0.10),
                Color(red: 0.69, green: 0.13, blue: 0.13),
                Color(red: 0.42, green: 0.07, blue: 0.07)
            )
        case .clean:
            return (
                Color(red: 0.10, green: 0.30, blue: 0.55),
                Color(red: 0.13, green: 0.38, blue: 0.69),
                Color(red: 0.07, green: 0.21, blue: 0.42)
            )
        case .remove:
            return (
                Color(red: 0.23, green: 0.23, blue: 0.23),
                Color(red: 0.31, green: 0.31, blue: 0.31),
                Color(red: 0.17, green: 0.17, blue: 0.17)
            )
        }
    }
}

// MARK: - Status

private enum StatusState {
    case idle
    case success(String)
    case error(String)
}

// MARK: - Palette constants

private extension Color {
    static let it7Bg       = Color(red: 0.11, green: 0.11, blue: 0.11)
    static let it7Panel    = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let it7HdrTop   = Color(red: 0.28, green: 0.28, blue: 0.28)
    static let it7HdrBot   = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let it7StatusBg = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let it7Blue     = Color(red: 0.29, green: 0.56, blue: 0.83)
    static let it7Dim      = Color(white: 0.47)
    static let it7Tiny     = Color(white: 0.33)
    static let it7SepDark  = Color(white: 0.07)
    static let it7SepLight = Color(white: 0.33)
    static let it7DropBg   = Color(red: 0.087, green: 0.087, blue: 0.087)
    static let it7DropAct  = Color(red: 0.055, green: 0.13,  blue: 0.21)
    static let it7DropBdr  = Color(white: 0.22)
    static let it7DropBdrA = Color(red: 0.29,  green: 0.50,  blue: 0.69)
    static let it7Success  = Color(red: 0.30, green: 0.69, blue: 0.43)
    static let it7Error    = Color(red: 0.80, green: 0.20, blue: 0.20)
}

// MARK: - Root view

struct ContentView: View {

    @State private var mode:         TagMode     = .explicit
    @State private var status:       StatusState = .idle
    @State private var lastFilename: String      = ""
    @State private var isDragging:   Bool        = false
    @State private var resetTask:    Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            divider
            modeRow
            divider
            dropZone
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            statusBar
        }
        .frame(width: 390, height: 330)
        .background(Color.it7Bg)
    }

    // ── Header ────────────────────────────────────────────────────────────────

    private var headerRow: some View {
        ZStack {
            LinearGradient(
                colors: [.it7HdrTop, .it7HdrBot],
                startPoint: .top, endPoint: .bottom
            )
            HStack(spacing: 0) {
                Text("♫")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.it7Blue)
                    .padding(.leading, 14)

                Text("  Advisory Tagger")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.white)

                Spacer()

                Text("iTunes Content Rating")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.it7Dim)
                    .padding(.trailing, 14)
            }
        }
        .frame(height: 52)
    }

    // ── Double-line separator ─────────────────────────────────────────────────

    private var divider: some View {
        VStack(spacing: 0) {
            Color.it7SepDark .frame(height: 1)
            Color.it7SepLight.frame(height: 1)
        }
    }

    // ── Mode buttons ──────────────────────────────────────────────────────────

    private var modeRow: some View {
        VStack(spacing: 6) {
            Text("SELECT MODE")
                .font(.system(size: 8, weight: .bold))
                .kerning(1.5)
                .foregroundStyle(Color.it7Tiny)

            HStack(spacing: 8) {
                ForEach(TagMode.allCases) { m in
                    ModeButton(
                        label:      m.label,
                        isSelected: mode == m,
                        colorN:     m.colorNormal,
                        colorH:     m.colorHover,
                        colorS:     m.colorSelected
                    ) {
                        mode = m
                        status = .idle
                        lastFilename = ""
                        resetTask?.cancel()
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.it7Panel)
    }

    // ── Drop zone ─────────────────────────────────────────────────────────────

    private var dropZone: some View {
        ZStack {
            // Background fill
            RoundedRectangle(cornerRadius: 5)
                .fill(isDragging ? Color.it7DropAct : Color.it7DropBg)
                .padding(14)

            // Border
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(
                    isDragging ? Color.it7DropBdrA : Color.it7DropBdr,
                    lineWidth: 2
                )
                .padding(14)

            // Content
            VStack(spacing: 6) {
                Text("⊕")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.it7Dim)

                Text(statusText)
                    .font(.system(size: 12))
                    .foregroundStyle(statusColor)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.15), value: statusText)

                if !lastFilename.isEmpty {
                    Text(lastFilename)
                        .font(.system(size: 9))
                        .foregroundStyle(Color.it7Dim)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 320)
                        .transition(.opacity)
                }
            }
        }
        // Accept file drops from Finder
        .onDrop(of: [UTType.fileURL], isTargeted: $isDragging) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadTransferable(type: URL.self) { result in
                DispatchQueue.main.async {
                    if case .success(let url) = result {
                        processFile(url)
                    }
                }
            }
            return true
        }
    }

    // ── Status bar ────────────────────────────────────────────────────────────

    private var statusBar: some View {
        ZStack {
            Color.it7StatusBg
            Text("Mode: \(mode.displayName)")
                .font(.system(size: 9))
                .foregroundStyle(Color.it7Blue)
        }
        .frame(height: 26)
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private var statusText: String {
        switch status {
        case .idle:           return "Drag & drop an .m4a file here"
        case .success(let s): return s
        case .error(let e):   return e
        }
    }

    private var statusColor: Color {
        switch status {
        case .idle:    return .it7Dim
        case .success: return .it7Success
        case .error:   return .it7Error
        }
    }

    private func processFile(_ url: URL) {
        guard url.pathExtension.lowercased() == "m4a" else {
            showStatus(.error("⚠  Only .m4a files are supported"))
            return
        }

        // Request security-scoped access (no-op for non-sandboxed apps, but
        // correct practice for when the app is ever sandboxed).
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            try MP4Tagger.setAdvisory(mode.advisoryValue, fileURL: url)
            lastFilename = url.lastPathComponent
            showStatus(.success("\(mode.successIcon)  Tagged as \(mode.displayName)!"),
                       autoreset: true)
        } catch {
            showStatus(.error("⚠  \(error.localizedDescription)"))
        }
    }

    private func showStatus(_ newStatus: StatusState, autoreset: Bool = false) {
        resetTask?.cancel()
        withAnimation { status = newStatus }
        if autoreset {
            resetTask = Task {
                try? await Task.sleep(for: .seconds(3.5))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation {
                        status = .idle
                        lastFilename = ""
                    }
                }
            }
        }
    }
}

// MARK: - ModeButton

/// Custom button that tracks hover state for the three mode selectors.
struct ModeButton: View {

    let label:      String
    let isSelected: Bool
    let colorN:     Color   // normal
    let colorH:     Color   // hovered
    let colorS:     Color   // selected / pressed
    let action:     () -> Void

    @State private var isHovered = false

    private var bgColor: Color {
        isSelected ? colorS : (isHovered ? colorH : colorN)
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 112, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(bgColor)
                        // Subtle inner-top highlight
                        .overlay(alignment: .top) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.07))
                                .frame(height: 14)
                                .clipped()
                        }
                        // Thin border
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
                        }
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.1), value: isHovered)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
        .cursor(.pointingHand)
    }
}

// MARK: - Pointer-cursor helper

private extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        onHover { inside in
            if inside { cursor.push() } else { NSCursor.pop() }
        }
    }
}
