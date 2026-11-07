//  PaletteHistoryItem.swift
//  ColourPalette
//
//  An automatic snapshot of a palette the moment it's *generated*. The
//  user never names these — they're just a recent-generations log they can
//  browse, reload, delete, or clear.

import SwiftUI

struct PaletteHistoryItem: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var swatches: [ColorSwatch]
    var date: Date = Date()

    // Derived helpers reused by the UI.
    var hexes: [String] { swatches.hexes }
    var exportText: String { swatches.exportText }

    init(id: UUID = UUID(), swatches: [ColorSwatch], date: Date = Date()) {
        self.id = id
        self.swatches = swatches.reidentified()
        self.date = date
    }

    /// A short preview like "#FF5E62 · #FF9966 · +3" for the list row.
    var displayText: String {
        let shown = Array(hexes.prefix(3)).map { "#\($0)" }.joined(separator: " · ")
        let remaining = hexes.count - 3
        return remaining > 0 ? "\(shown) · +\(remaining)" : shown
    }
}

// MARK: - Formatting

extension PaletteHistoryItem {
    /// "2 Oct, 3:04 PM" — for the list row.
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}