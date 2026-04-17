// MP4Tagger.swift
// Directly patches the `rtng` (iTunes advisory) atom inside an M4A/MP4 file.
// No external dependencies — pure Swift byte manipulation.
//
// Atom path written:  moov ▶ udta ▶ meta ▶ ilst ▶ rtng ▶ data
// rtng values:        0 = none/remove   1 = explicit   2 = clean

import Foundation

// MARK: - Public error type

enum MP4TaggerError: LocalizedError {
    case notAnMP4File
    case missingAtom(String)
    case corruptAtom(String)

    var errorDescription: String? {
        switch self {
        case .notAnMP4File:
            return "File does not appear to be a valid M4A / MP4 file."
        case .missingAtom(let name):
            return "Required metadata structure '\(name)' was not found. "
                 + "The file may not have iTunes-style metadata."
        case .corruptAtom(let detail):
            return "Unexpected file structure: \(detail)"
        }
    }
}

// MARK: - Public API

struct MP4Tagger {

    /// Write `value` into the iTunes advisory (`rtng`) atom of the file at `url`.
    /// Creates the atom if it does not already exist; overwrites if it does.
    /// Writes are atomic (temp file + rename).
    static func setAdvisory(_ value: UInt8, fileURL url: URL) throws {
        var bytes = try Array(Data(contentsOf: url))
        try patchBytes(&bytes, advisory: value)
        try Data(bytes).write(to: url, options: .atomic)
    }
}

// MARK: - Core patching logic

private extension MP4Tagger {

    // ── Box descriptor ────────────────────────────────────────────────────────

    struct Box {
        /// Byte offset of the 4-byte size field (first byte of the box).
        let start: Int
        /// Byte offset of the first byte *past* this box.
        let end: Int
        /// Byte offset of the first content byte (right after the 8-byte header).
        let contentStart: Int
    }

    // ── Entry point ───────────────────────────────────────────────────────────

    static func patchBytes(_ b: inout [UInt8], advisory: UInt8) throws {
        let n = b.count

        // Walk the atom tree: moov ▶ udta ▶ meta ▶ ilst
        guard let moov = findBox(b, fourCC: "moov", from: 0,                    limit: n)    else { throw MP4TaggerError.missingAtom("moov") }
        guard let udta = findBox(b, fourCC: "udta", from: moov.contentStart,    limit: moov.end) else { throw MP4TaggerError.missingAtom("udta") }
        guard let meta = findBox(b, fourCC: "meta", from: udta.contentStart,    limit: udta.end) else { throw MP4TaggerError.missingAtom("meta") }

        // `meta` is a FullBox — its first 4 content bytes are version + flags,
        // not a child atom.  Skip them when searching for `ilst`.
        let ilstSearch = meta.contentStart + 4
        guard let ilst = findBox(b, fourCC: "ilst", from: ilstSearch,           limit: meta.end) else { throw MP4TaggerError.missingAtom("ilst") }

        // ── Case A: rtng already exists — just patch the value byte ──────────
        if let rtng = findBox(b, fourCC: "rtng", from: ilst.contentStart, limit: ilst.end),
           let data = findBox(b, fourCC: "data", from: rtng.contentStart, limit: rtng.end) {
            // data box content layout:
            //   [4 bytes] well-known type (0x15 = integer)
            //   [4 bytes] locale (0x00000000)
            //   [N bytes] value  ← we want offset +8 from contentStart
            let valueOffset = data.contentStart + 8
            guard valueOffset < b.count else {
                throw MP4TaggerError.corruptAtom("rtng/data value byte missing")
            }
            b[valueOffset] = advisory
            return
        }

        // ── Case B: no rtng yet — build and insert one ────────────────────────
        let newAtom = buildRtngAtom(value: advisory)
        let insertAt = ilst.contentStart        // prepend inside ilst

        b.insert(contentsOf: newAtom, at: insertAt)

        // All enclosing boxes start before `insertAt`, so their offsets are
        // unchanged and we can safely patch their sizes.
        let delta = UInt32(newAtom.count)
        patchSize(&b, at: ilst.start, adding: delta)
        patchSize(&b, at: meta.start, adding: delta)
        patchSize(&b, at: udta.start, adding: delta)
        patchSize(&b, at: moov.start, adding: delta)
    }

    // ── Atom search ───────────────────────────────────────────────────────────

    /// Linear scan for the first box named `fourCC` in the byte range [from, limit).
    static func findBox(_ b: [UInt8], fourCC: String, from: Int, limit: Int) -> Box? {
        let tag = Array(fourCC.utf8)
        guard tag.count == 4 else { return nil }
        var i = from
        while i + 8 <= limit {
            let size = Int(readBE32(b, at: i))
            guard size >= 8 else { return nil }          // size 0 / corrupt
            let boxEnd = i + size
            if b[i+4] == tag[0] && b[i+5] == tag[1]
            && b[i+6] == tag[2] && b[i+7] == tag[3] {
                return Box(start: i, end: min(boxEnd, limit), contentStart: i + 8)
            }
            if boxEnd >= limit { break }
            i = boxEnd
        }
        return nil
    }

    // ── Atom builder ──────────────────────────────────────────────────────────

    /// Constructs a complete rtng atom ready to splice into the ilst:
    ///
    ///   rtng (25 bytes)
    ///   └── data (17 bytes)
    ///         type  = 0x00000015  (BE integer)
    ///         locale= 0x00000000
    ///         value = <1 byte>
    static func buildRtngAtom(value: UInt8) -> [UInt8] {
        // data box: 8 header + 4 type + 4 locale + 1 value = 17 bytes
        var data: [UInt8] = []
        data += be32(17)
        data += Array("data".utf8)
        data += be32(0x00000015)   // well-known type: signed integer
        data += be32(0x00000000)   // locale
        data.append(value)

        // rtng box: 8 header + data box = 25 bytes
        var rtng: [UInt8] = []
        rtng += be32(UInt32(8 + data.count))
        rtng += Array("rtng".utf8)
        rtng += data

        return rtng
    }

    // ── Byte helpers ──────────────────────────────────────────────────────────

    static func readBE32(_ b: [UInt8], at i: Int) -> UInt32 {
        (UInt32(b[i]) << 24) | (UInt32(b[i+1]) << 16)
            | (UInt32(b[i+2]) << 8) | UInt32(b[i+3])
    }

    static func be32(_ v: UInt32) -> [UInt8] {
        [UInt8(v >> 24), UInt8((v >> 16) & 0xFF),
         UInt8((v >> 8)  & 0xFF), UInt8(v & 0xFF)]
    }

    static func patchSize(_ b: inout [UInt8], at i: Int, adding delta: UInt32) {
        let newSize = be32(readBE32(b, at: i) + delta)
        b.replaceSubrange(i ..< i + 4, with: newSize)
    }
}
