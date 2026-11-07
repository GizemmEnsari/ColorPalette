//  PalettePreview.swift
//  ColourPalette
//
//  A small horizontal strip of colour cells, reused as the thumbnail for
//  preset rows, saved-palette rows, and history rows.

import SwiftUI

struct PalettePreview: View {

    let swatches: [ColorSwatch]
    var height: CGFloat = 30
    var cornerRadius: CGFloat = 6
    var spacing: CGFloat = 1

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(swatches) { swatch in
                swatch.swiftUIColor
                    .frame(height: height)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    PalettePreview(swatches: ColorPresets.all[0].swatches)
        .frame(width: 160)
        .padding()
}