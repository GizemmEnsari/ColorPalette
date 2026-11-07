//  HistoryView.swift
//  ColourPalette
//
//  A log of every palette that has been generated. Each row can be:
//   • tapped -> load it into the live palette
//   • swiped -> delete just that entry
// A "Clear" toolbar button wipes the whole log.

import SwiftUI

struct HistoryView: View {

    @EnvironmentObject var viewModel: PaletteViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showClearConfirm = false

    var body: some View {
        Group {
            if viewModel.history.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.history.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                }
            }
        }
        .confirmationDialog("Clear entire history?",
                            isPresented: $showClearConfirm,
                            titleVisibility: .visible) {
            Button("Clear All", role: .destructive) { viewModel.clearHistory() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: List

    private var list: some View {
        List {
            ForEach(viewModel.history) { item in
                row(for: item)
            }
        }
        .listStyle(.plain)
    }

    private func row(for item: PaletteHistoryItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayText)
                    .font(.body.monospaced())
                    .lineLimit(1)
                Text(item.dateFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            PalettePreview(swatches: item.swatches, height: 30)
                .frame(width: 90)
        }
        .contentShape(Rectangle())
        .onTapGesture { load(item) }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteHistory(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button { load(item) } label: { Label("Load", systemImage: "arrow.down.circle") }
            Button(role: .destructive) {
                viewModel.deleteHistory(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No history yet")
                .foregroundColor(.secondary)
            Text("Every palette you generate is logged here.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: Actions

    private func load(_ item: PaletteHistoryItem) {
        withAnimation { viewModel.loadHistory(item) }
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HistoryView()
    }
    .environmentObject(PaletteViewModel())
}