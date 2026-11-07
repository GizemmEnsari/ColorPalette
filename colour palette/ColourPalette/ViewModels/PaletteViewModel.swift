//  PaletteViewModel.swift
//  ColourPalette
//
//  Holds the shared app state:
//   • the live 5-colour palette (`swatches`)
//   • `savedPalettes` — the user's personal, renamable library
//   • `history` — an automatic log of recently generated palettes
//   • a transient `toastMessage` for copy / save feedback
//
//  All palette *actions* live here so the views stay declarative and the
//  logic is fully unit-testable on its own. Persistence mirrors the
//  QRCodeApp pattern: `PropertyListEncoder` + `FileManager` round-trips to
//  the app's Documents directory — one file per collection.

import SwiftUI
import UIKit

@MainActor
final class PaletteViewModel: ObservableObject {

    // MARK: Constants

    /// How many colours make up a palette (matches Coolors' 5-swatch layout).
    static let swatchCount = 5

    /// Cap on how many generated palettes we keep in `history`.
    static let maxHistory = 100

    // MARK: Published state

    /// The live palette. Always exactly `swatchCount` entries.
    @Published var swatches: [ColorSwatch]

    /// The user's saved, renamable palettes (most-recent first).
    @Published var savedPalettes: [SavedPalette]

    /// Recently generated palettes (most-recent first), auto-captured.
    @Published var history: [PaletteHistoryItem]

    /// A short, transient confirmation string shown after a copy/export.
    @Published var toastMessage: String?

    // MARK: Persistence

    private static let liveFileName    = "palette.plist"
    private static let savedFileName   = "saved_palettes.plist"
    private static let historyFileName = "palette_history.plist"

    private static func documentsURL(_ file: String) -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(file)
    }

    // MARK: Init

    init() {
        // Compute every starting value *before* `self` exists: Swift
        // requires all stored properties be set before any instance method
        // can be called, so the loads live in `static` helpers.
        self.swatches      = PaletteViewModel.loadSwatches()      ?? Self.makeRandomPalette()
        self.savedPalettes = PaletteViewModel.loadSavedPalettes() ?? []
        self.history       = PaletteViewModel.loadHistory()       ?? []
    }

    // MARK: - Generate & history

    /// Re-roll every *unlocked* swatch to a new random colour, then record
    /// the freshly generated palette into `history`. Locked swatches keep
    /// their colour — that's the whole point of locking.
    func generate() {
        // Nothing to do if everything is pinned.
        if swatches.allSatisfy(\.isLocked) {
            setToast("Unlock a colour to generate")
            return
        }

        for index in swatches.indices where !swatches[index].isLocked {
            swatches[index] = .random()
        }

        recordHistory()
        saveAll()
        setToast("Generated a new palette")
    }

    /// Push a snapshot of the *current* palette into the history log.
    private func recordHistory() {
        history.insert(PaletteHistoryItem(swatches: swatches), at: 0)
        if history.count > Self.maxHistory {
            history.removeLast(history.count - Self.maxHistory)
        }
    }

    // MARK: - Locking

    /// Toggle a single swatch between locked / unlocked.
    func toggleLock(at index: Int) {
        guard swatches.indices.contains(index) else { return }
        swatches[index].isLocked.toggle()
        saveAll()
    }

    /// Lock every swatch in one tap.
    func lockAll() {
        for index in swatches.indices { swatches[index].isLocked = true }
        saveAll()
        setToast("All colours locked")
    }

    /// Unlock every swatch in one tap.
    func unlockAll() {
        for index in swatches.indices { swatches[index].isLocked = false }
        saveAll()
        setToast("All colours unlocked")
    }

    // MARK: - Presets

    /// Apply a curated preset, replacing the live palette entirely.
    func apply(preset: PresetPalette) {
        swatches = preset.swatches.reidentified()
        saveAll()
        setToast("Applied “\(preset.name)”")
    }

    // MARK: - Saved library

    /// Save the current live palette into the user's library under `name`.
    /// Falls back to a default name if the user leaves it blank.
    @discardableResult
    func saveCurrent(name rawName: String = "") -> SavedPalette {
        let name = Self.fallbackName(rawName: rawName)
        let saved = SavedPalette.snapshot(from: swatches, named: name)
        savedPalettes.insert(saved, at: 0)
        saveAll()
        setToast("Saved “\(name)”")
        return saved
    }

    /// Rename a saved palette.
    func renameSaved(_ id: UUID, to name: String) {
        guard let index = savedPalettes.firstIndex(where: { $0.id == id }) else { return }
        savedPalettes[index].name = name
        saveAll()
    }

    /// Duplicate a saved palette (inserted just below the original).
    func duplicateSaved(_ id: UUID) {
        guard let index = savedPalettes.firstIndex(where: { $0.id == id }) else { return }
        var copy = savedPalettes[index]
        copy.id = UUID()
        copy.name = savedPalettes[index].name + " (copy)"
        copy.date = Date()
        savedPalettes.insert(copy, at: index + 1)
        saveAll()
        setToast("Duplicated “\(copy.name)”")
    }

    /// Delete a single saved palette.
    func deleteSaved(_ id: UUID) {
        savedPalettes.removeAll { $0.id == id }
        saveAll()
    }

    /// Clear the entire saved library.
    func clearSaved() {
        savedPalettes.removeAll()
        saveAll()
        setToast("Saved palettes cleared")
    }

    /// Load a saved palette back into the live list.
    func loadSaved(_ id: UUID) {
        guard let saved = savedPalettes.first(where: { $0.id == id }) else { return }
        swatches = saved.swatches.reidentified()
        saveAll()
        setToast("Loaded “\(saved.name)”")
    }

    // MARK: - History actions

    /// Load a previously generated palette back into the live list.
    func loadHistory(_ item: PaletteHistoryItem) {
        swatches = item.swatches.reidentified()
        saveAll()
        setToast("Loaded a past palette")
    }

    /// Delete a single history entry.
    func deleteHistory(_ item: PaletteHistoryItem) {
        history.removeAll { $0.id == item.id }
        saveAll()
    }

    /// Clear the entire history log.
    func clearHistory() {
        history.removeAll()
        saveAll()
        setToast("History cleared")
    }

    // MARK: - Clipboard

    /// Copy a single swatch's hex to the clipboard.
    func copyHex(at index: Int) {
        guard swatches.indices.contains(index) else { return }
        UIPasteboard.general.string = swatches[index].hex
        setToast("Copied  \(swatches[index].hex)")
    }

    /// Copy the whole palette (one hex per line) to the clipboard.
    func copyAll() {
        UIPasteboard.general.string = swatches.exportText
        setToast("Copied \(swatches.count) colours")
    }

    // MARK: - Export / share

    /// The palette as plain text, ready to hand to a `ShareLink`.
    var exportText: String { swatches.exportText }

    /// A horizontal strip image of the palette for the share sheet / Photos.
    var shareImage: UIImage? {
        PaletteImageExporter.makeImage(from: swatches.hexes)
    }

    // MARK: - Toast

    /// Show a transient message, auto-cleared after a moment.
    private func setToast(_ message: String) {
        toastMessage = message
    }

    // MARK: - Helpers

    /// Trims a user-entered name; if blank, uses a plain default so names
    /// are never empty.
    static func fallbackName(rawName: String) -> String {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Palette" : trimmed
    }

    // MARK: - Persistence helpers

    private static func makeRandomPalette() -> [ColorSwatch] {
        (0..<swatchCount).map { _ in .random() }
    }

    /// Persist all three collections at once.
    private func saveAll() {
        let encoder = PropertyListEncoder()
        if let d = try? encoder.encode(swatches)      { try? d.write(to: Self.documentsURL(Self.liveFileName),    options: .atomic) }
        if let d = try? encoder.encode(savedPalettes) { try? d.write(to: Self.documentsURL(Self.savedFileName),   options: .atomic) }
        if let d = try? encoder.encode(history)       { try? d.write(to: Self.documentsURL(Self.historyFileName), options: .atomic) }
    }

    private static func loadSwatches() -> [ColorSwatch]? {
        guard let data = try? Data(contentsOf: documentsURL(liveFileName)),
              let decoded = try? PropertyListDecoder().decode([ColorSwatch].self, from: data),
              !decoded.isEmpty else { return nil }
        return decoded
    }

    private static func loadSavedPalettes() -> [SavedPalette]? {
        guard let data = try? Data(contentsOf: documentsURL(savedFileName)),
              let decoded = try? PropertyListDecoder().decode([SavedPalette].self, from: data) else {
            return nil
        }
        return decoded
    }

    private static func loadHistory() -> [PaletteHistoryItem]? {
        guard let data = try? Data(contentsOf: documentsURL(historyFileName)),
              let decoded = try? PropertyListDecoder().decode([PaletteHistoryItem].self, from: data) else {
            return nil
        }
        return decoded
    }
}