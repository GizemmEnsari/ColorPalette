# Colour Palette — iOS Color Palette Picker

A **native, offline** color-palette generator for iPhone built with
**SwiftUI**. Tap to generate a fresh 5-colour palette, **lock** the
colours you love, **copy** any hex to the clipboard, and **export** the
whole thing as text or a shareable image. No server, no database, no
network calls — everything runs on-device.

---

## ✨ Features

| Feature | Details |
|---|---|
| **5-colour palette** | A vertical stack of 5 full-bleed colour bars, Coolors-style |
| **Generate** | One tap re-rolls every *unlocked* colour using a "random hue" algorithm (always lively, never muddy) |
| **Lock individual colours** | Tap the lock icon on any bar to keep that colour when you regenerate |
| **Lock / Unlock all** | Bulk buttons to freeze or free the whole palette at once |
| **Copy a hex** | Tap any colour bar to copy its `#RRGGBB` to the clipboard (with a toast confirmation) |
| **Copy all** | One tap copies the whole palette, one hex per line |
| **Adaptive text** | Hex labels auto-switch between black and white (WCAG luminance) so they're always readable |
| **Share & export** | A `UIActivityViewController` share sheet (the `ShareSheet` wrapper) shares the hex list **and** a rendered strip image in one tap |
| **Persistence** | Your last palette is saved to disk and restored on launch |
| **Dark mode** | Fully supports system dark mode |
| **Offline** | Zero network requests |

---

## 📂 Project Structure

```
colour palette/
├── project.yml                              # XcodeGen config
├── README.md
├── .gitignore
└── ColourPalette/
    ├── ColourPaletteApp.swift               # @main entry point
    ├── ContentView.swift                    # Root NavigationStack
    ├── Models/
    │   └── ColorSwatch.swift                # Codable swatch (RGB + isLocked, hex derived)
    ├── ViewModels/
    │   └── PaletteViewModel.swift           # generate / lock / copy / export + persistence
    ├── Views/
    │   ├── PaletteView.swift                # The main screen (5 bars + action bar + toast)
    │   └── ColorBarView.swift               # A single colour bar (tap to copy, lock icon)
    ├── Utilities/
    │   └── Color+Hex.swift                  # Hex<->RGB, generation, contrast, image export
    ├── Assets.xcassets/                     # AppIcon, AccentColor
    │   ├── AppIcon.appiconset/
    │   ├── AccentColor.colorset/
    │   └── Contents.json
    ├── Preview Content/
    │   └── Preview Assets.xcassets/
    └── ColourPaletteTests/
        └── ColourPaletteTests.swift         # XCTest unit tests
```

---

## 🚀 How to Build & Run

### Option A — XcodeGen (recommended, one command)

1. **Install XcodeGen** (if you don't have it):
   ```bash
   brew install xcodegen
   ```

2. **Generate the project** from this folder:
   ```bash
   cd "colour palette"
   xcodegen generate
   ```

3. **Open the project**:
   ```bash
   open ColourPalette.xcodeproj
   ```

4. In Xcode:
   - Select an **iPhone 15** simulator (or any iOS 16+ device).
   - Press **⌘R** to build and run.

### Option B — Manual Xcode setup

1. Open **Xcode** → **File → New → Project**.
2. Choose **iOS → App** → Next.
3. Set:
   - **Product Name**: `Colour Palette`
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Minimum Deployment Target**: **iOS 16.0**
4. Click **Create**.
5. In the navigator, delete the auto-generated `ContentView.swift`.
6. **Drag every `.swift` file** from the `ColourPalette/` folder into the
   **ColourPalette** target group (make sure "Target: Colour Palette"
   is checked when the dialog appears).
7. Drag the `Assets.xcassets` and `Preview Content/` folders into the project.

---

## 🔧 How It Works

### The "random hue" generator (`PaletteGenerator.randomColor()`)

Naively picking random R, G, B values produces a lot of dull, muddy
colours. Instead we work in **HSB**:

```
pick random hue        (0–360°, any direction on the colour wheel)
pick saturation 0.55–0.85   (vivid, but not neon)
pick lightness  0.30–0.70   (readable, never pure black/white)
        │
        ▼
UIColor(hue:saturation:lightness:)  ->  RGB  ->  "#RRGGBB"
```

This guarantees every generated colour is pleasant and usable.

### Locking

Each `ColorSwatch` carries an `isLocked` flag. When `generate()` runs it
**skips any locked swatch**, only re-rolling the unlocked ones. That's the
core "Coolors" behaviour: pin the colours you like and keep shuffling the
rest.

### Adaptive text colour

`TextContrast.shouldUseDarkText(on:)` computes the WCAG *relative
luminance* of a colour. If it's above 0.5 the hex label is drawn in black,
otherwise white — so the text is always legible on its own background.

### Key Concepts

- **`ColorSwatch`** — a `Codable` value whose single source of truth is the
  integer `RGB` triple; the hex string, the `Color`, and the readable text
  colour are all *derived* from it, so it can never fall out of sync.
- **`@Published` in `PaletteViewModel`** — when a swatch changes, SwiftUI
  re-renders the relevant bar automatically.
- **`ShareSheet` (UIActivityViewController)** — the native share sheet,
  presented from SwiftUI via a `UIViewControllerRepresentable`. We use this
  instead of `ShareLink` because we share *multiple* items (hex text + image).
- **`UIGraphicsImageRenderer`** — draws the 5-colour strip into a `UIImage`
  for sharing / saving to Photos.
- **`PropertyListEncoder` / `FileManager`** — the last palette is persisted
  to the app's sandbox Documents directory as a `.plist`, same pattern as
  the sibling QRCodeApp.

---

## 🧪 Running Tests

In Xcode:
- **Product → Test** (⌘U) to run all unit tests.
- Tests cover: hex↔RGB round-trips, malformed-hex handling, 3-digit
  shorthand, luminance / text-contrast choices, the random generator,
  lock/unlock behaviour, "locked swatch survives generate", export text,
  image export, and a full persistence round-trip.

---

## 📱 Testing on a Real iPhone

1. In Xcode, go to **Product → Destination** and select your iPhone
   (or **More Devices** to register it).
2. You'll need a **free Apple Developer account**
   (just sign in with your Apple ID — no $99/year needed for personal testing).
3. Set **Signing & Capabilities** in the project settings:
   - **Team**: Your free Apple ID
   - **Bundle Identifier**: `com.YOURNAME.ColourPalette` (must be unique)
   - In `project.yml`, set `DEVELOPMENT_TEAM` to your team ID and
     `CODE_SIGNING_ALLOWED: "YES"` before regenerating.
4. Press **⌘R** — Xcode will build and install the app on your phone.

> **Tip**: With a free account you can run the app for 7 days before
> you need to re-sign. For development that's usually fine.

---

## 🎨 Customisation Ideas

The codebase is structured so these are easy to add:

- **Analogous / monochrome / complementary** mode switches — add a
  generation strategy alongside the current "random hue" one.
- **Save palettes to a library** — store multiple `PaletteViewModel`
  snapshots to disk, like QRCodeApp's history.
- **Import a hex** — add a text field that decodes a pasted hex.
- **Contrast checker** — reuse `TextContrast` to warn about low-contrast pairs.
- **Per-swatch rename / tag** — add fields to `ColorSwatch` (keep `Codable`).

---

## 📝 Requirements

- **Xcode 15+**
- **iOS 16+** (for `UIActivityViewController`, `NavigationStack`, `.ultraThinMaterial`)
- **Swift 5.9+**
- **XcodeGen** (optional, for automated project generation)

No external dependencies. No server. No network.

---

## ⚠️ Before App Store Submission

- Add a real **App Icon** (1024×1024 PNG) to `Assets.xcassets/AppIcon.appiconset/`.
- Add a `PrivacyInfo.xcprivacy` file if Apple requires one for your
  app category (not needed for simulator / personal use).
- Set a proper **Development Team** and **Bundle Identifier** in
  `project.yml` before signing.