//  ContentView.swift
//  ColourPalette
//
//  The root of the view hierarchy. Wraps the single `PaletteView` in a
//  `NavigationStack` so its navigation title + toolbar work.

import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationStack {
            PaletteView()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(PaletteViewModel())
}