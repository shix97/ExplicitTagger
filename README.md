# ExplicitTagger

A lightweight macOS utility for setting iTunes content advisory tags on AAC and Apple Lossless audio files. Drag in a file, pick a mode, done.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![Universal](https://img.shields.io/badge/arch-universal-lightgrey)

---

## What it does

ExplicitTagger writes directly to the `rtng` atom inside the MP4 container of `.m4a` and `.alac` files — the same metadata field iTunes and Apple Music read to display the **E** or **CLEAN** badge on a track. No iTunes required, no third-party libraries, just pure Swift byte manipulation.

Three modes:

| Button | Tag value | Result in iTunes / Apple Music |
|--------|-----------|-------------------------------|
| **Explicit** | `1` | Shows **E** badge |
| **Clean** | `2` | Shows **CLEAN** badge |
| **Remove Tag** | `0` | Removes advisory entirely |

---

## Features

- Drag and drop `.m4a` or `.alac` files onto the window, or click to open via file picker
- Creates the `rtng` atom from scratch if one doesn't already exist
- Patches atom tree sizes all the way up (`ilst → meta → udta → moov`) for spec-compliant output
- Writes are atomic (temp file + rename) — original is never left in a partial state
- Universal binary — runs natively on Apple Silicon and Intel
- Retro Aqua-inspired UI, no Electron, no Python, no dependencies

---

## Requirements

- macOS 13 Ventura or later
- Xcode command line tools (for building)

---

## Disclaimer

ExplicitTagger is an independent utility and has no affiliation with Apple Inc. iTunes and Apple Music are trademarks of Apple Inc.
