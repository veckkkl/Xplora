//
//  StatisticsCardsScrollAnimator.swift
//  Xplora
//

import UIKit

final class StatisticsCardsScrollAnimator {

    // MARK: - Constants

    private let collapseRange: CGFloat = 120
    private let maxScale: CGFloat = 0.06
    private let maxTranslateY: CGFloat = 18
    private let maxAlphaLoss: CGFloat = 0.18

    // MARK: - Update

    func update(cards: [UIView], in containerView: UIView, collapseStartY: CGFloat) {
        for card in cards {
            let frame = card.convert(card.bounds, to: containerView)
            let overlap = collapseStartY - frame.minY
            let progress = min(1, max(0, overlap / collapseRange))

            guard progress > 0 else {
                if card.transform != .identity { card.transform = .identity }
                if card.alpha != 1 { card.alpha = 1 }
                continue
            }

            let scale = 1 - progress * maxScale
            let ty = -progress * maxTranslateY
            card.transform = CGAffineTransform(translationX: 0, y: ty).scaledBy(x: scale, y: scale)
            card.alpha = 1 - progress * maxAlphaLoss
        }
    }
}
