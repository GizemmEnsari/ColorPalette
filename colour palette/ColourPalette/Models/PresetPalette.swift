//  PresetPalette.swift
//  ColourPalette
//
//  A curated, ready-made 5-colour palette the user can apply with one tap.
//  `ColorPresets` holds the built-in library. Each preset is just a name +
//  five hex codes, so adding more presets is a one-liner.

import SwiftUI

struct PresetPalette: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var swatches: [ColorSwatch]

    // Derived helpers reused by the UI.
    var hexes: [String] { swatches.hexes }
    var exportText: String { swatches.exportText }

    init(id: UUID = UUID(), name: String, swatches: [ColorSwatch]) {
        self.id = id
        self.name = name
        self.swatches = swatches
    }
}

// MARK: - Factory

extension PresetPalette {
    /// Build a preset from a name + a list of hex strings.
    static func make(_ name: String, _ hexes: [String]) -> PresetPalette {
        PresetPalette(name: name, swatches: hexes.map { ColorSwatch(hex: $0, isLocked: false) })
    }
}

// MARK: - The built-in library

/// A hand-picked set of 5-colour palettes across common moods/themes.
/// Ordered roughly from warm → cool → neutral so the grid reads nicely.
enum ColorPresets {

    static let all: [PresetPalette] = [
        .make("Sunset",     ["FF5E62", "FF9966", "FFC87A", "FFDDAA", "FFF2CC"]),
        .make("Ocean",      ["012A4A", "01497C", "2A6F97", "619CBA", "A6D8E2"]),
        .make("Forest",     ["0B3D2E", "145A32", "2E8B57", "8FBC8F", "D8F3DC"]),
        .make("Berry",      ["2D1B2E", "4A2545", "7B2D5E", "B23A6E", "F28AB2"]),
        .make("Peach",      ["FFE5D9", "FEC89A", "F19066", "DE6B48", "C74B32"]),
        .make("Mint",       ["004B43", "0B6E4F", "10B981", "6EE7B7", "D1FAE5"]),
        .make("Grape",      ["2B0F54", "3D1E7A", "6A3FB5", "A56CE0", "E0C3FC"]),
        .make("Citrus",     ["FFD500", "FFA500", "FF7000", "E65C00", "B34700"]),
        .make("Slate",      ["0F172A", "1E293B", "334155", "64748B", "CBD5E1"]),
        .make("Rose",       ["780000", "BB2626", "F87171", "FDA4AF", "FECDD3"]),
        .make("Teal",       ["003D5B", "00798C", "00B4C8", "7DE2DC", "E0FFFF"]),
        .make("Lavender",   ["2E1A47", "4B2E83", "7B4FB5", "B19CD9", "E8DAF5"]),
        .make("Charcoal",   ["0A0A0A", "1C1C1C", "333333", "666666", "AAAAAA"]),
        .make("Pastel",     ["FFB3BA", "FFDFBA", "FFFFBA", "BAFFC1", "BAE1FF"]),
        .make("Aurora",     ["0B132B", "1C2541", "3A506B", "5BC0BE", "6FFFE9"]),
        .make("Terracotta", ["3E2723", "795548", "A1887F", "D7CCC8", "EFEBE9"]),
        .make("Neon",       ["0D0D0D", "FF0055", "00E5FF", "FFE600", "00FF85"]),
        .make("Warm",       ["5C3D2E", "9C6B3F", "C89B5E", "E8C07D", "F5E1B4"]),
        .make("Cool",       ["0A1931", "16425B", "2E86AB", "A2D5F2", "E8F1F8"]),
        .make("Candy",      ["FF6392", "FF8C69", "FFD166", "8AC926", "52B69A"]),
        .make("Monochrome", ["0D0D0D", "333333", "666666", "999999", "CCCCCC"]),
        .make("Coral",      ["023047", "219EBC", "8ECAE6", "FFE5D9", "FFB4A2"]),
        .make("Ember",      ["03071E", "370617", "6A040F", "A4161A", "E85D04"]),
        .make("Sky",        ["011627", "014F6A", "2E8BB0", "80C9E0", "CDEEF7"]),
        .make("Golden",     ["422006", "774936", "C08552", "E8B45E", "F5E6C8"]),
    ]

    /// The first preset, used as a friendly default.
    static var first: PresetPalette { all[0] }
}