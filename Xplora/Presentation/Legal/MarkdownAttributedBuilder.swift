//
//  MarkdownAttributedBuilder.swift
//  Xplora
//

import UIKit

/// Renders the small Markdown subset used by bundled legal documents
/// (h1 `#`, h2 `##`, `**bold**`, `-` bullets, `---` rules, paragraphs)
/// into a readable `NSAttributedString`. Block-level structure only; no
/// links or nested lists are expected in these documents.
enum MarkdownAttributedBuilder {
    static func attributedString(from markdown: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty { continue }

            if trimmed == "---" || trimmed == "***" {
                result.append(NSAttributedString(string: "\n", attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .footnote),
                    .paragraphStyle: spacingParagraphStyle(after: 8)
                ]))
                continue
            }

            if trimmed.hasPrefix("## ") {
                appendBlock(String(trimmed.dropFirst(3)), to: result, style: .heading2)
            } else if trimmed.hasPrefix("# ") {
                appendBlock(String(trimmed.dropFirst(2)), to: result, style: .heading1)
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                appendBlock(String(trimmed.dropFirst(2)), to: result, style: .bullet)
            } else {
                appendBlock(trimmed, to: result, style: .body)
            }
        }

        return result
    }

    // MARK: - Block styling

    private enum BlockStyle {
        case heading1
        case heading2
        case bullet
        case body
    }

    private static func appendBlock(_ text: String, to result: NSMutableAttributedString, style: BlockStyle) {
        let prefix = style == .bullet ? "•  " : ""
        let inline = inlineAttributedString(
            from: prefix + text,
            baseFont: baseFont(for: style),
            color: color(for: style)
        )
        let mutable = NSMutableAttributedString(attributedString: inline)
        mutable.addAttribute(
            .paragraphStyle,
            value: paragraphStyle(for: style),
            range: NSRange(location: 0, length: mutable.length)
        )
        mutable.append(NSAttributedString(string: "\n"))
        result.append(mutable)
    }

    private static func baseFont(for style: BlockStyle) -> UIFont {
        switch style {
        case .heading1:
            return scaledFont(.systemFont(ofSize: 28, weight: .bold), textStyle: .largeTitle)
        case .heading2:
            return scaledFont(.systemFont(ofSize: 20, weight: .semibold), textStyle: .title3)
        case .bullet, .body:
            return UIFont.preferredFont(forTextStyle: .body)
        }
    }

    private static func color(for style: BlockStyle) -> UIColor {
        switch style {
        case .heading1, .heading2:
            return .label
        case .bullet, .body:
            return .secondaryLabel
        }
    }

    private static func paragraphStyle(for style: BlockStyle) -> NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        switch style {
        case .heading1:
            paragraph.paragraphSpacingBefore = 8
            paragraph.paragraphSpacing = 8
        case .heading2:
            paragraph.paragraphSpacingBefore = 14
            paragraph.paragraphSpacing = 6
        case .bullet:
            paragraph.paragraphSpacing = 4
            paragraph.firstLineHeadIndent = 0
            paragraph.headIndent = 18
            paragraph.lineSpacing = 2
        case .body:
            paragraph.paragraphSpacing = 8
            paragraph.lineSpacing = 3
        }
        return paragraph
    }

    private static func spacingParagraphStyle(after spacing: CGFloat) -> NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.paragraphSpacing = spacing
        return paragraph
    }

    // MARK: - Inline styling (**bold**)

    private static func inlineAttributedString(from text: String, baseFont: UIFont, color: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let segments = text.components(separatedBy: "**")
        let boldFont = baseFont.boldVariant

        for (index, segment) in segments.enumerated() where !segment.isEmpty {
            let isBold = index % 2 == 1
            result.append(NSAttributedString(string: segment, attributes: [
                .font: isBold ? boldFont : baseFont,
                .foregroundColor: color
            ]))
        }

        return result
    }

    private static func scaledFont(_ font: UIFont, textStyle: UIFont.TextStyle) -> UIFont {
        UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
    }
}

private extension UIFont {
    var boldVariant: UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(
            fontDescriptor.symbolicTraits.union(.traitBold)
        ) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
