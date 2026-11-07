//  ColourPaletteTests.swift
//  ColourPalette
//
//  Unit tests for the hex/RGB helpers, the random generator, and the
//  view model. Run via Xcode: Product → Test (⌘U).

import XCTest
import UIKit
@testable import ColourPalette

// MARK: - Hex <-> RGB

final class HexColorTests: XCTestCase {

    func testHexStringFromRGB() {
        XCTAssertEqual(HexColor.hexString(from: RGB(red: 58, green: 123, blue: 213)), "3A7BD5")
        XCTAssertEqual(HexColor.hexString(from: RGB(red: 0, green: 0, blue: 0)), "000000")
        XCTAssertEqual(HexColor.hexString(from: RGB(red: 255, green: 255, blue: 255)), "FFFFFF")
    }

    func testDisplayHexHasLeadingHash() {
        XCTAssertEqual(HexColor.displayHex(from: RGB(red: 255, green: 0, blue: 0)), "#FF0000")
    }

    func testRGBFromHexFullForm() {
        XCTAssertEqual(HexColor.rgb(fromHex: "3A7BD5"), RGB(red: 58, green: 123, blue: 213))
    }

    func testRGBFromHexWithHash() {
        XCTAssertEqual(HexColor.rgb(fromHex: "#3A7BD5"), RGB(red: 58, green: 123, blue: 213))
    }

    func testRGBFromHexLowercase() {
        XCTAssertEqual(HexColor.rgb(fromHex: "3a7bd5"), RGB(red: 58, green: 123, blue: 213))
    }

    func testRGBFromHexThreeDigitShorthand() {
        XCTAssertEqual(HexColor.rgb(fromHex: "F80"), RGB(red: 255, green: 136, blue: 0))
    }

    func testRGBFromHexWhitespaceTolerant() {
        XCTAssertEqual(HexColor.rgb(fromHex: "  # 3A7BD5  "), RGB(red: 58, green: 123, blue: 213))
    }

    func testMalformedHexReturnsNil() {
        XCTAssertNil(HexColor.rgb(fromHex: "XYZ"))
        XCTAssertNil(HexColor.rgb(fromHex: "12345"))   // wrong length
        XCTAssertNil(HexColor.rgb(fromHex: ""))
        XCTAssertNil(HexColor.rgb(fromHex: "GGGGGG"))   // non-hex
    }

    func testHexRoundTrip() {
        for rgb in [RGB(red: 1, green: 2, blue: 3),
                    RGB(red: 255, green: 128, blue: 0),
                    RGB(red: 128, green: 128, blue: 128)] {
            let hex = HexColor.hexString(from: rgb)
            XCTAssertEqual(HexColor.rgb(fromHex: hex), rgb, "Round-trip failed for \(rgb)")
        }
    }

    func testRGBClampsOutOfRange() {
        // init masks with 0xFF, so 300 -> 44, -1 -> 255
        XCTAssertEqual(RGB(red: 300, green: -1, blue: 0), RGB(red: 44, green: 255, blue: 0))
    }
}

// MARK: - Text contrast

final class TextContrastTests: XCTestCase {

    func testPureWhiteUsesDarkText() {
        XCTAssertTrue(TextContrast.shouldUseDarkText(on: RGB(red: 255, green: 255, blue: 255)))
    }

    func testPureBlackUsesLightText() {
        XCTAssertFalse(TextContrast.shouldUseDarkText(on: RGB(red: 0, green: 0, blue: 0)))
    }

    func testLuminanceInRange() {
        for rgb in [RGB(red: 0, green: 0, blue: 0),
                    RGB(red: 255, green: 255, blue: 255),
                    RGB(red: 128, green: 128, blue: 128)] {
            let l = TextContrast.luminance(of: rgb)
            XCTAssertGreaterThanOrEqual(l, 0.0)
            XCTAssertLessThanOrEqual(l, 1.0)
        }
    }

    func testBrighterColorHasHigherLuminance() {
        let light = TextContrast.luminance(of: RGB(red: 200, green: 200, blue: 200))
        let dark  = TextContrast.luminance(of: RGB(red: 50, green: 50, blue: 50))
        XCTAssertGreaterThan(light, dark)
    }
}

// MARK: - Model

final class ColorSwatchTests: XCTestCase {

    func testSwatchHexIsDerivedFromRGB() {
        let swatch = ColorSwatch(rgb: RGB(red: 255, green: 0, blue: 0))
        XCTAssertEqual(swatch.hex, "FF0000")
        XCTAssertEqual(swatch.displayHex, "#FF0000")
    }

    func testSwatchInitFromHexFallsBackToBlackWhenMalformed() {
        let swatch = ColorSwatch(hex: "not-a-color")
        XCTAssertEqual(swatch.rgb, RGB(red: 0, green: 0, blue: 0))
    }

    func testRandomProducesDistinctSwatches() {
        // 50 random colours should not all collapse to a single value.
        var seen = Set<String>()
        for _ in 0..<50 {
            seen.insert(ColorSwatch.random().hex)
        }
        XCTAssertGreaterThan(seen.count, 1)
    }

    func testPaletteExportTextIsHexPerLine() {
        let palette: [ColorSwatch] = [
            ColorSwatch(rgb: RGB(red: 255, green: 0, blue: 0)),
            ColorSwatch(rgb: RGB(red: 0, green: 255, blue: 0)),
        ]
        XCTAssertEqual(palette.exportText, "FF0000\n00FF00")
        XCTAssertEqual(palette.hexes, ["FF0000", "00FF00"])
    }

    func testSwatchIsCodable() throws {
        let swatch = ColorSwatch(rgb: RGB(red: 10, green: 20, blue: 30), isLocked: true)
        let data = try PropertyListEncoder().encode(swatch)
        let decoded = try PropertyListDecoder().decode(ColorSwatch.self, from: data)
        XCTAssertEqual(decoded.rgb, RGB(red: 10, green: 20, blue: 30))
        XCTAssertTrue(decoded.isLocked)
    }
}

// MARK: - Image export

final class PaletteImageExporterTests: XCTestCase {

    func testMakeImageFromHexes() {
        let image = PaletteImageExporter.makeImage(from: ["FF0000", "00FF00", "0000FF"])
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image!.size.width, 0)
    }

    func testMakeImageEmptyReturnsNil() {
        XCTAssertNil(PaletteImageExporter.makeImage(from: []))
    }
}

// MARK: - Shared helpers

/// Remove every persisted palette file so each test starts from a clean slate.
private func clearAllPaletteFiles() {
    let documents = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)
        .first!
    for name in ["palette.plist", "saved_palettes.plist", "palette_history.plist"] {
        try? FileManager.default.removeItem(at: documents.appendingPathComponent(name))
    }
}

// MARK: - Presets

@MainActor
final class PresetTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        clearAllPaletteFiles()
    }

    func testLibraryIsPopulated() {
        XCTAssertFalse(ColorPresets.all.isEmpty)
        for preset in ColorPresets.all {
            XCTAssertEqual(preset.swatches.count, 5,
                           "\(preset.name) should have exactly five swatches")
            XCTAssertTrue(preset.swatches.allSatisfy { !$0.hex.isEmpty },
                          "\(preset.name) should have no empty hexes")
        }
    }

    func testApplyPresetReplacesLivePalette() {
        let vm = PaletteViewModel()
        let preset = ColorPresets.all.first!
        vm.apply(preset: preset)
        XCTAssertEqual(vm.swatches.map(\.hex), preset.swatches.map(\.hex))
    }
}

// MARK: - Saved library

@MainActor
final class SavedLibraryTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        clearAllPaletteFiles()
    }

    func testSaveCurrentThenLoadRestoresPalette() {
        let vm = PaletteViewModel()
        vm.generate()
        let before = vm.swatches.map(\.hex)
        vm.saveCurrent(name: "My Set")
        XCTAssertEqual(vm.savedPalettes.count, 1)
        XCTAssertEqual(vm.savedPalettes.first?.name, "My Set")

        // Mutate the live palette, then load the saved one back.
        vm.generate()
        vm.loadSaved(vm.savedPalettes[0].id)
        XCTAssertEqual(vm.swatches.map(\.hex), before)
    }

    func testRenameDuplicateAndDelete() {
        let vm = PaletteViewModel()
        vm.generate()
        vm.saveCurrent(name: "Original")
        let savedId = vm.savedPalettes[0].id

        vm.renameSaved(savedId, to: "Renamed")
        XCTAssertEqual(vm.savedPalettes.first?.name, "Renamed")

        vm.duplicateSaved(savedId)
        XCTAssertEqual(vm.savedPalettes.count, 2)

        vm.deleteSaved(savedId)
        XCTAssertEqual(vm.savedPalettes.count, 1)
    }

    func testClearSaved() {
        let vm = PaletteViewModel()
        vm.generate()
        vm.saveCurrent(name: "A")
        vm.saveCurrent(name: "B")
        XCTAssertGreaterThan(vm.savedPalettes.count, 0)
        vm.clearSaved()
        XCTAssertTrue(vm.savedPalettes.isEmpty)
    }

    func testSavedPalettesPersistAcrossInstances() {
        let vm = PaletteViewModel()
        vm.generate()
        vm.saveCurrent(name: "Persistent")

        let vm2 = PaletteViewModel()
        XCTAssertEqual(vm2.savedPalettes.count, 1)
        XCTAssertEqual(vm2.savedPalettes.first?.name, "Persistent")
    }
}

// MARK: - History

@MainActor
final class HistoryTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        clearAllPaletteFiles()
    }

    func testGenerateRecordsHistory() {
        let vm = PaletteViewModel()
        vm.generate()
        XCTAssertEqual(vm.history.count, 1)
        XCTAssertNotNil(vm.history.first)
    }

    func testLoadHistoryRestoresPalette() {
        let vm = PaletteViewModel()
        vm.generate()
        let snapshot = vm.history[0]
        vm.generate()
        vm.loadHistory(snapshot)
        XCTAssertEqual(vm.swatches.map(\.hex), snapshot.swatches.map(\.hex))
    }

    func testHistoryCapAtMax() {
        let vm = PaletteViewModel()
        for _ in 0..<(PaletteViewModel.maxHistory + 50) {
            vm.generate()
        }
        XCTAssertEqual(vm.history.count, PaletteViewModel.maxHistory)
    }

    func testAllLockedGenerateDoesNotRecordHistory() {
        let vm = PaletteViewModel()
        vm.lockAll()
        vm.generate()
        XCTAssertTrue(vm.history.isEmpty, "An all-locked generate should not add to history")
    }

    func testClearHistory() {
        let vm = PaletteViewModel()
        vm.generate()
        vm.generate()
        XCTAssertFalse(vm.history.isEmpty)
        vm.clearHistory()
        XCTAssertTrue(vm.history.isEmpty)
    }

    func testHistoryPersistsAcrossInstances() {
        let vm = PaletteViewModel()
        vm.generate()
        vm.generate()

        let vm2 = PaletteViewModel()
        XCTAssertEqual(vm2.history.count, 2)
    }
}

// MARK: - View model

@MainActor
final class PaletteViewModelTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        clearAllPaletteFiles()
    }

    func testInitialStateHasFiveSwatches() {
        let vm = PaletteViewModel()
        XCTAssertEqual(vm.swatches.count, PaletteViewModel.swatchCount)
    }

    func testGenerateReshufflesUnlocked() {
        let vm = PaletteViewModel()
        vm.generate()
        XCTAssertEqual(vm.swatches.count, 5)   // still five, just new colours
    }

    func testLockedSwatchKeepsColourOnGenerate() {
        let vm = PaletteViewModel()
        vm.toggleLock(at: 0)
        let lockedHex = vm.swatches[0].hex

        // Generate many times — the locked swatch must stay put.
        for _ in 0..<20 {
            vm.generate()
        }
        XCTAssertEqual(vm.swatches[0].hex, lockedHex, "Locked swatch should not change")
    }

    func testToggleLock() {
        let vm = PaletteViewModel()
        XCTAssertFalse(vm.swatches[1].isLocked)
        vm.toggleLock(at: 1)
        XCTAssertTrue(vm.swatches[1].isLocked)
        vm.toggleLock(at: 1)
        XCTAssertFalse(vm.swatches[1].isLocked)
    }

    func testLockAllAndUnlockAll() {
        let vm = PaletteViewModel()
        vm.lockAll()
        XCTAssertTrue(vm.swatches.allSatisfy { $0.isLocked })

        vm.unlockAll()
        XCTAssertTrue(vm.swatches.allSatisfy { !$0.isLocked })
    }

    func testExportTextMatchesSwatchHexes() {
        let vm = PaletteViewModel()
        let expected = vm.swatches.map(\.hex).joined(separator: "\n")
        XCTAssertEqual(vm.exportText, expected)
        XCTAssertEqual(vm.exportText.split(separator: "\n").count, 5)
    }

    func testPersistenceRoundTrip() {
        let vm = PaletteViewModel()
        vm.generate()
        let savedHexes = vm.swatches.map(\.hex)

        // A fresh view model should read the same palette back from disk.
        let vm2 = PaletteViewModel()
        XCTAssertEqual(vm2.swatches.map(\.hex), savedHexes)
    }
}