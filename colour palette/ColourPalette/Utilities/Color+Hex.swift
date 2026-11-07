//  Color+Hex.swift
//  ColourPalette
//
//  Pure, testable helpers that live at the heart of the whole app:
//
//   • Hex  <-> RGB  conversions (e.g. "3A7BD5" <-> (58, 123, 213))
//   • A `randomColor()` using the "random hue" algorithm
//     (random hue, fixed-ish saturation/lightness) so every generated
//     colour is pleasant and never an ugly muddy grey.
//   • `shouldUseDarkText(on:)` — WCAG-style luminance test that picks
//     black or white text so a hex label is always readable on its bar.
//   • `makeImage(from:)` — renders a palette into a PNG for export/sharing.
//
//  Everything here is a free `static` function so the unit tests can
//  exercise it without a SwiftUI or UIKit view being on screen.

import SwiftUI
import UIKit

// MARK: - RGB value type

/// A simple 0–255 RGB triple. Kept as a value type so it can be stored,
/// encoded, and compared cheaply inside `ColorSwatch`.
struct RGB: Equatable, Codable {
    var red: Int
    var green: Int
    var blue: Int

    init(red: Int, green: Int, blue: Int) {
        self.red   = red   & 0xFF
        self.green = green & 0xFF
        self.blue  = blue  & 0xFF
    }
}

// MARK: - Hex <-> RGB

enum HexColor {

    // MARK: RGB -> hex

    /// "3A7BD5" — no leading `#`, always upper-cased.
    static func hexString(from rgb: RGB) -> String {
        String(format: "%02X%02X%02X", rgb.red, rgb.green, rgb.blue)
    }

    /// "#3A7BD5" — the same string with a leading hash, for display.
    static func displayHex(from rgb: RGB) -> String {
        "#" + hexString(from: rgb)
    }

    // MARK: hex -> RGB

    /// Parse "3A7BD5", "#3A7BD5", or even "3a7bd5".
    /// Returns `nil` for malformed input so callers can fall back safely.
    static func rgb(fromHex hex: String) -> RGB? {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        // Re-trim: a stray space after the hash ("# 3A7BD5") is common.
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        // Accept 3-digit shorthand like "F80" -> "FF8800".
        if cleaned.count == 3 {
            let chars = Array(cleaned)
            cleaned = chars.flatMap { String(repeating: String($0), count: 2) }.joined()
        }
        guard cleaned.count == 6,
              let value = Int(cleaned, radix: 16) else {
            return nil
        }
        let red   = (value >> 16) & 0xFF
        let green = (value >> 8) & 0xFF
        let blue  = value & 0xFF
        return RGB(red: red, green: green, blue: blue)
    }

    // MARK: -> UIColor / SwiftUI Color

    static func uiColor(from rgb: RGB) -> UIColor {
        UIColor(
            red:   CGFloat(rgb.red)   / 255.0,
            green: CGFloat(rgb.green) / 255.0,
            blue:  CGFloat(rgb.blue)  / 255.0,
            alpha: 1.0
        )
    }

    static func color(from rgb: RGB) -> Color {
        Color(
            red:   Double(rgb.red)   / 255.0,
            green: Double(rgb.green) / 255.0,
            blue:  Double(rgb.blue)  / 255.0
        )
    }
}

// MARK: - Generation

enum PaletteGenerator {

    /// The "random hue" algorithm.
    ///
    /// Instead of a totally random RGB (which can produce dull, muddy
    /// colours) we pick a **random hue** and a comfortably saturated,
    /// mid-lightness value. The result is always a lively, usable colour.
    static func randomColor() -> RGB {
        let hue        = CGFloat.random(in: 0.0 ... 1.0)      // 0–360°
        let saturation = CGFloat.random(in: 0.55 ... 0.85)    // vivid but not neon
        let lightness  = CGFloat.random(in: 0.30 ... 0.70)    // readable, not too dark/light
        let color = UIColor(hue: hue, saturation: saturation, brightness: lightness, alpha: 1.0)
        return rgb(from: color)
    }

    /// Convert any `UIColor` into an integer `RGB` triple.
    static func rgb(from color: UIColor) -> RGB {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return RGB(
            red:   Int((r * 255).rounded()),
            green: Int((g * 255).rounded()),
            blue:  Int((b * 255).rounded())
        )
    }
}

// MARK: - Text colour (readability)

enum TextContrast {

    /// Relative luminance (0–1) using the sRGB linearisation that WCAG uses.
    static func luminance(of rgb: RGB) -> Double {
        func channel(_ value: Int) -> Double {
            let c = Double(value) / 255.0
            return c <= 0.03928
                ? c / 12.92
                : pow((c + 0.055) / 1.055, 2.4)
        }
        let r = channel(rgb.red), g = channel(rgb.green), b = channel(rgb.blue)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// `true` when dark text reads better (i.e. the background is light).
    /// A 0.5 threshold on luminance is the classic, reliable choice.
    static func shouldUseDarkText(on rgb: RGB) -> Bool {
        luminance(of: rgb) > 0.5
    }

    /// The SwiftUI text colour that stays readable on this swatch.
    static func textColor(on rgb: RGB) -> Color {
        shouldUseDarkText(on: rgb) ? .black : .white
    }
}

// MARK: - Image export

enum PaletteImageExporter {

    /// Renders the palette as a single horizontal strip of solid colour
    /// blocks — handy for the iOS share sheet / saving to Photos.
    static func makeImage(
        from hexes: [String],
        size: CGSize = CGSize(width: 1200, height: 400)
    ) -> UIImage? {
        let colors = hexes.compactMap { HexColor.rgb(fromHex: $0) }
        guard !colors.isEmpty else { return nil }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext
            let blockWidth = size.width / CGFloat(colors.count)

            for (index, rgb) in colors.enumerated() {
                cg.setFillColor(HexColor.uiColor(from: rgb).cgColor)
                let rect = CGRect(
                    x: blockWidth * CGFloat(index),
                    y: 0,
                    width: blockWidth,
                    height: size.height
                )
                cg.fill(rect)
            }
        }
    }
}