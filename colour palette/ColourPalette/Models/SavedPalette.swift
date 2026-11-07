//  SavedPalette.swift
//  ColourPalette
//
//  A palette the user has explicitly *saved* to their personal library.
//  Unlike history, a saved palette has a user-editable `name` so they can
//  organise it, then later rename / duplicate / delete / export / reload it.

import SwiftUI

struct SavedPalette: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var name: String
    var swatches: [ColorSwatch]
    var date: Date = Date()

    // Derived helpers reused by the UI.
    var hexes: [String] { swatches.hexes }
    var exportText: String { swatches.exportText }

    init(id: UUID = UUID(), name: String, swatches: [ColorSwatch], date: Date = Date()) {
        self.id = id
        self.name = name
        self.swatches = swatches
        self.date = date
    }

    /// A snapshot of the live palette with a (possibly default) name.
    static func snapshot(from swatches: [ColorSwatch], named name: String) -> SavedPalette {
        SavedPalette(name: name, swatches: swatches.reidentified())
    }
}

// MARK: - Formatting

extension SavedPalette {
    /// "Saved 2 Oct, 3:04 PM" — for the list row.
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Saved " + formatter.string(from: date)
    }
}