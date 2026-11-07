//  ColourPaletteApp.swift
//  ColourPalette
//
//  App entry point. Creates the shared `PaletteViewModel` once and hands
//  it to the whole view hierarchy as an `@EnvironmentObject`, exactly like
//  the sibling QRCodeApp / GraphStudio projects.

import SwiftUI

@main
struct ColourPaletteApp: App {

    @StateObject private var viewModel = PaletteViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}