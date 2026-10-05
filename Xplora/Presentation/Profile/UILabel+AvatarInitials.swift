//
//  UILabel+AvatarInitials.swift
//  Xplora
//

import UIKit

extension UILabel {
    /// Shows the initials, or a neutral person glyph sized to the label's font
    /// when there are none.
    func setAvatarInitials(_ initials: String?) {
        if let initials {
            text = initials
            return
        }

        let symbolConfiguration = UIImage.SymbolConfiguration(font: font)
        guard let image = UIImage(systemName: "person.fill", withConfiguration: symbolConfiguration) else {
            text = nil
            return
        }
        let glyph = NSMutableAttributedString(attachment: NSTextAttachment(image: image))
        glyph.addAttribute(.foregroundColor, value: textColor ?? .label, range: NSRange(location: 0, length: glyph.length))
        attributedText = glyph
    }
}
