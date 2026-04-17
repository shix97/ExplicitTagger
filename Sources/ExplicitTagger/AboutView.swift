// AboutView.swift
// Shown when the user clicks "About ExplicitTagger" in the macOS menu bar.

import SwiftUI

struct AboutView: View {

    var body: some View {
        VStack(spacing: 0) {
            // ── Icon ──────────────────────────────────────────────────────────
            Group {
                if let img = loadBundledIcon() {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .cornerRadius(20)
                } else {
                    // Fallback if icon isn't bundled yet
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "#c4c4c4"))
                        .frame(width: 96, height: 96)
                        .overlay(
                            Text("ET")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        )
                }
            }
            .padding(.top, 28)

            // ── App name ──────────────────────────────────────────────────────
            Text("ExplicitTagger")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.top, 14)

            Divider()
                .padding(.horizontal, 40)
                .padding(.vertical, 14)

            // ── Credits block — centered, one item per line ───────────────────
            VStack(spacing: 6) {
                Text("Version 1.1 (1.1)")
                    .font(.system(size: 12))

                Text("By Shix")
                    .font(.system(size: 12))

                Text("· · ·")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)

                Text("No Affiliation with Apple")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)

            Spacer(minLength: 24)
        }
        .frame(width: 320, height: 270)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
