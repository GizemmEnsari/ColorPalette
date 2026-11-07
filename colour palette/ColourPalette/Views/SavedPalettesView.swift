//  SavedPalettesView.swift
//  ColourPalette
//
//  The user's saved-palette library. Each row can be:
//   • tapped        -> load it into the live palette
//   • swiped        -> delete it
//   • context menu  -> Rename / Duplicate / Share / Delete
// A "Clear" toolbar button wipes the whole library.

import SwiftUI
import UIKit

struct SavedPalettesView: View {

    @EnvironmentObject var viewModel: PaletteViewModel
    @Environment(\.dismiss) private var dismiss

    // Rename prompt
    @State private var renameTarget: SavedPalette?
    @State private var renameText = ""
    @State private var showRenameAlert = false

    // Share
    @State private var shareItems: [Any] = []
    @State private var showShare = false

    // Clear confirmation
    @State private var showClearConfirm = false

    var body: some View {
        Group {
            if viewModel.savedPalettes.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.savedPalettes.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                }
            }
        }
        .confirmationDialog("Clear entire library?",
                            isPresented: $showClearConfirm,
                            titleVisibility: .visible) {
            Button("Clear All", role: .destructive) { viewModel.clearSaved() }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Rename palette", isPresented: $showRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Save", role: .none) {
                if let target = renameTarget {
                    viewModel.renameSaved(target.id, to: renameText)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Give this palette a new name.")
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
    }

    // MARK: List

    private var list: some View {
        List {
            ForEach(viewModel.savedPalettes) { palette in
                row(for: palette)
            }
        }
        .listStyle(.plain)
    }

    private func row(for palette: SavedPalette) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(palette.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(palette.dateFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            PalettePreview(swatches: palette.swatches, height: 30)
                .frame(width: 90)
        }
        .contentShape(Rectangle())
        .onTapGesture { load(palette) }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteSaved(palette.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button { load(palette) } label: { Label("Load", systemImage: "arrow.down.circle") }
            Button { startRename(palette) } label: { Label("Rename", systemImage: "pencil") }
            Button { viewModel.duplicateSaved(palette.id) } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
            Button { startShare(palette) } label: { Label("Share", systemImage: "square.and.arrow.up") }
            Divider()
            Button(role: .destructive) {
                viewModel.deleteSaved(palette.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No saved palettes yet")
                .foregroundColor(.secondary)
            Text("Tap “Save” on the main screen to keep a palette here.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: Actions

    private func load(_ palette: SavedPalette) {
        withAnimation { viewModel.loadSaved(palette.id) }
        dismiss()
    }

    private func startRename(_ palette: SavedPalette) {
        renameTarget = palette
        renameText = palette.name
        showRenameAlert = true
    }

    private func startShare(_ palette: SavedPalette) {
        var items: [Any] = [palette.exportText]
        if let image = PaletteImageExporter.makeImage(from: palette.hexes) {
            items.append(image)
        }
        shareItems = items
        showShare = true
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SavedPalettesView()
    }
    .environmentObject(PaletteViewModel())
}