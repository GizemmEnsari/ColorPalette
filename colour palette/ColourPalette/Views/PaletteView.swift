//  PaletteView.swift
//  ColourPalette
//
//  The one and only screen. Top-to-bottom:
//   • A vertical stack of 5 full-bleed colour bars (each = tap to copy,
//     tap the lock icon to lock/unlock).
//   • A bottom bar with the primary actions: Generate, Lock all, Unlock,
//     Copy all, and Share (opens the native share sheet).
//   • A transient "toast" for copy feedback.

import SwiftUI
import UIKit

struct PaletteView: View {

    @EnvironmentObject var viewModel: PaletteViewModel

    // Local UI state
    @State private var toastDismissWorkItem: DispatchWorkItem?
    @State private var showShare = false

    // Navigation to the library screens.
    @State private var route: PaletteRoute?

    // "Save palette" name prompt.
    @State private var showSavePrompt = false
    @State private var newPaletteName = ""

    var body: some View {
        VStack(spacing: 0) {
            paletteStack
            actionBar
        }
        .background(Color(.systemBackground))
        .navigationTitle("Colour Palette")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // Presets / Saved / History, bundled into one menu.
                Menu {
                    Button { route = .presets } label: { Label("Presets", systemImage: "square.grid.2x2") }
                    Button { route = .saved }   label: { Label("Saved Palettes", systemImage: "bookmark") }
                    Button { route = .history } label: { Label("History", systemImage: "clock") }
                } label: {
                    Image(systemName: "tray")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                // Share everything (hex text + strip image) in one tap.
                Button {
                    showShare = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .overlay(alignment: .bottom) { toast }
        .onChange(of: viewModel.toastMessage) { newValue in
            scheduleToastDismiss(message: newValue)
        }
        .navigationDestination(item: $route) { route in
            switch route {
            case .presets: PresetsView()
            case .saved:   SavedPalettesView()
            case .history: HistoryView()
            }
        }
        .alert("Save Palette", isPresented: $showSavePrompt) {
            TextField("Name", text: $newPaletteName)
            Button("Save", role: .none) {
                viewModel.saveCurrent(name: newPaletteName)
                newPaletteName = ""
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Save the current palette to your library.")
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
    }

    // MARK: - Share payload

    private var shareItems: [Any] {
        var items: [Any] = [viewModel.exportText]
        if let image = viewModel.shareImage {
            items.append(image)
        }
        return items
    }

    // MARK: - The 5 colour bars

    private var paletteStack: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.swatches.enumerated()), id: \.element.id) { index, swatch in
                ColorBarView(
                    swatch: swatch,
                    onToggleLock: { viewModel.toggleLock(at: index) },
                    onCopy:       { viewModel.copyHex(at: index) }
                )
                .frame(height: 92)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: viewModel.swatches[index].rgb)
            }
        }
    }

    // MARK: - Bottom action bar

    private var actionBar: some View {
        VStack(spacing: 16) {
            // Primary "Generate" button.
            Button {
                withAnimation { viewModel.generate() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "wand.and.stars")
                        .font(.title3)
                    Text("Generate")
                        .font(.title3.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                actionBarButton("Save",     "square.and.arrow.down", action: startSave)
                actionBarButton("Copy All", "doc.on.doc",            action: viewModel.copyAll)
                actionBarButton("Lock All", "lock",                  action: viewModel.lockAll)
                actionBarButton("Unlock",   "lock.open",             action: viewModel.unlockAll)
            }
        }
        .padding()
        .background(
            Color(.systemGroupedBackground)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func actionBarButton(
        _ title: String,
        _ systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .foregroundColor(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toast

    @ViewBuilder
    private var toast: some View {
        if let message = viewModel.toastMessage {
            Text(message)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    /// Whenever a new toast message appears, schedule it to clear itself
    /// after ~1.6s so it never lingers. A new message cancels the prior
    /// timer, so rapid copies don't clear each other out early.
    private func scheduleToastDismiss(message: String?) {
        toastDismissWorkItem?.cancel()
        guard let message else { return }
        let workItem = DispatchWorkItem {
            DispatchQueue.main.async {
                withAnimation {
                    if viewModel.toastMessage == message {
                        viewModel.toastMessage = nil
                    }
                }
            }
        }
        toastDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: workItem)
    }

    /// Open the "Save Palette" name prompt.
    private func startSave() {
        newPaletteName = ""
        showSavePrompt = true
    }
}

// MARK: - Routes

/// The three library screens reachable from the main screen's toolbar menu.
enum PaletteRoute: Hashable, Identifiable {
    case presets, saved, history
    var id: Self { self }
}

// MARK: - Share sheet wrapper

/// Wraps `UIActivityViewController` so it can be presented from SwiftUI.
/// Used instead of `ShareLink` because we want to share *multiple* items
/// (the hex text *and* the rendered strip image) in one sheet.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PaletteView()
    }
    .environmentObject(PaletteViewModel())
}