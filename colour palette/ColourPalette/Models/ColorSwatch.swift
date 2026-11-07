//  ColorSwatch.swift
//  ColourPalette
//
//  A single colour in the palette.
//
//  The single source of truth is the integer `RGB` triple — everything
//  else (the hex string, the SwiftUI/UIColor, the readable text colour)
//  is *derived* from it, so the model can never fall out of sync with
//  its own display.
//
//  `isLocked` is the one piece of per-swatch UI state: a locked swatch
//  keeps its colour when the user hits "Generate".

import SwiftUI

struct ColorSwatch: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var rgb: RGB
    var isLocked: Bool = false

    // MARK: Hex (derived from RGB — the canonical form)

    /// "3A7BD5" — what gets copied to the clipboard and exported.
    var hex: String { HexColor.hexString(from: rgb) }

    /// "#3A7BD5" — what the user sees on the bar.
    var displayHex: String { HexColor.displayHex(from: rgb) }

    // MARK: Colours (derived from RGB)

    var uiColor: UIColor { HexColor.uiColor(from: rgb) }
    var swiftUIColor: Color { HexColor.color(from: rgb) }

    /// Black or white, whichever stays readable on this colour.
    var textColor: Color { TextContrast.textColor(on: rgb) }

    // MARK: Init

    init(rgb: RGB, isLocked: Bool = false) {
        self.rgb = rgb
        self.isLocked = isLocked
    }

    /// Build a swatch from an existing hex string, falling back to black
    /// if the string is malformed (defensive — keeps decoding robust).
    init(hex: String, isLocked: Bool = false) {
        self.rgb = HexColor.rgb(fromHex: hex) ?? RGB(red: 0, green: 0, blue: 0)
        self.isLocked = isLocked
    }

    /// A brand-new random, unlocked swatch.
    static func random() -> ColorSwatch {
        ColorSwatch(rgb: PaletteGenerator.randomColor())
    }

    /// A copy with a fresh `id` — used when loading a preset / saved /
    /// history palette so the live list never reuses a stale identity.
    func withNewID() -> ColorSwatch {
        var copy = self
        copy.id = UUID()
        return copy
    }
}

// MARK: - Convenience accessors on the whole palette

extension Array where Element == ColorSwatch {
    /// Every hex code, in order — used for copy-all / export / share.
    var hexes: [String] { map(\.hex) }

    /// The palette formatted as one hex per line for export.
    var exportText: String { hexes.joined(separator: "\n") }

    /// A copy of the whole palette with fresh `id`s (used when loading a
    /// preset / saved / history palette into the live list).
    func reidentified() -> [ColorSwatch] { map { $0.withNewID() } }
}