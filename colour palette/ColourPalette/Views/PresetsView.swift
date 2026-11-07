//  PresetsView.swift
//  ColourPalette
//
//  A browsable grid of the built-in `ColorPresets` library. Tapping any
//  preset loads it into the live palette (via the view model) and shows a
//  toast. This is the "more preset colours" surface.

import SwiftUI

struct PresetsView: View {

    @EnvironmentObject var viewModel: PaletteViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ColorPresets.all) { preset in
                    Button {
                        withAnimation { viewModel.apply(preset: preset) }
                    } label: {
                        PresetCard(preset: preset)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Presets")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Card

private struct PresetCard: View {
    let preset: PresetPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PalettePreview(swatches: preset.swatches, height: 44)
            Text(preset.name)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PresetsView()
    }
    .environmentObject(PaletteViewModel())
}