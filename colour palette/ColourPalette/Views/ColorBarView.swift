//  ColorBarView.swift
//  ColourPalette
//
//  One horizontal colour bar: a tap copies its hex, a small control on
//  the right locks / unlocks it. The hex label auto-switches between
//  black and white so it's always readable (see `TextContrast`).

import SwiftUI

struct ColorBarView: View {

    let swatch: ColorSwatch
    var onToggleLock: () -> Void
    var onCopy: () -> Void

    var body: some View {
        HStack {
            Spacer()

            VStack(spacing: 6) {
                if swatch.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(swatch.textColor.opacity(0.85))
                }

                Text(swatch.displayHex)
                    .font(.system(.title3, design: .monospaced, weight: .semibold))
                    .foregroundColor(swatch.textColor)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture(perform: onCopy)

            // Lock toggle sits in its own tappable area so it doesn't
            // fire the "copy" gesture on the main bar.
            Button(action: onToggleLock) {
                Image(systemName: swatch.isLocked ? "lock.open.fill" : "lock")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(swatch.textColor.opacity(0.9))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(swatch.swiftUIColor)
    }
}

// MARK: - Preview

#Preview {
    ColorBarView(
        swatch: ColorSwatch(rgb: RGB(red: 58, green: 123, blue: 213), isLocked: false),
        onToggleLock: {},
        onCopy: {}
    )
    .frame(height: 90)
}