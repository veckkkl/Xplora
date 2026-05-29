//
//  NoteTextHighlighter.swift
//  Xplora
//

import UIKit

/// Pure helper that performs case-insensitive substring matching against a
/// note's text and produces a styled `NSAttributedString` with all matches
/// highlighted, plus the active match emphasised with a stronger style.
///
/// The view controller owns search-UI state (current query, current match
/// index, search-nav buttons) and side effects on `UITextView`. This type
/// only computes the attributed text and the list of match ranges.
enum NoteTextHighlighter {
    struct Result {
        let attributedText: NSAttributedString
        let matches: [NSRange]
    }

    /// - Parameters:
    ///   - text: full plain text of the note.
    ///   - query: search query; an empty string yields no matches and a plain
    ///     base-styled string.
    ///   - activeMatchIndex: index of the match that should receive
    ///     `activeMatchAttributes`. Clamped internally to the valid range.
    ///     Pass `nil` to skip active-match emphasis.
    ///   - baseAttributes: attributes applied to the whole string.
    ///   - matchAttributes: attributes added to every match range.
    ///   - activeMatchAttributes: attributes applied to the active match
    ///     range; keys overwrite values from `matchAttributes` for that range.
    static func highlight(
        text: String,
        query: String,
        activeMatchIndex: Int?,
        baseAttributes: [NSAttributedString.Key: Any],
        matchAttributes: [NSAttributedString.Key: Any],
        activeMatchAttributes: [NSAttributedString.Key: Any]
    ) -> Result {
        guard !query.isEmpty else {
            return Result(
                attributedText: NSAttributedString(string: text, attributes: baseAttributes),
                matches: []
            )
        }

        let attributed = NSMutableAttributedString(string: text, attributes: baseAttributes)

        let lowercasedText = text.lowercased()
        let lowercasedQuery = query.lowercased()
        var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex
        var matches: [NSRange] = []

        while let range = lowercasedText.range(of: lowercasedQuery, options: [], range: searchRange) {
            let nsRange = NSRange(range, in: lowercasedText)
            matches.append(nsRange)
            attributed.addAttributes(matchAttributes, range: nsRange)
            searchRange = range.upperBound..<lowercasedText.endIndex
        }

        if !matches.isEmpty, let active = activeMatchIndex {
            let clampedActive = min(max(active, 0), matches.count - 1)
            attributed.addAttributes(activeMatchAttributes, range: matches[clampedActive])
        }

        return Result(attributedText: attributed, matches: matches)
    }
}
