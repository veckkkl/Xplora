//
//  TripPhotoPresentationMetrics.swift
//  Xplora
//

import UIKit

struct TripPhotoWidthPolicy {
    let widthRatio: CGFloat
    let maxWidth: CGFloat
    let minWidth: CGFloat

    func resolvedWidth(for availableWidth: CGFloat) -> CGFloat {
        let ratioWidth = availableWidth * widthRatio
        return max(minWidth, min(maxWidth, ratioWidth))
    }
}

enum TripPhotoPresentationMetrics {
    static let noteCollageWidthPolicy = TripPhotoWidthPolicy(
        widthRatio: 0.98,
        maxWidth: .greatestFiniteMagnitude,
        minWidth: 0
    )
    // Note-screen collage is scaled 1.5× taller than the list preview so the
    // user can actually see the photos they attached. All three values bump
    // together (engine multiplier × scale, the width-relative cap, and the
    // pixel floor for short collages) so the proportional growth holds for
    // every layout case from 1 to 10 photos.
    static let noteCollageHeightScale: CGFloat = 0.93
    static let noteCollageMaxHeightRatio: CGFloat = 0.81
    static let noteCollageMinHeight: CGFloat = 192

    static let notePlaceholderWidthPolicy = TripPhotoWidthPolicy(
        widthRatio: 0.98,
        maxWidth: .greatestFiniteMagnitude,
        minWidth: 0
    )
    static let notePlaceholderHeightRatio: CGFloat = 0.36
    static let notePlaceholderMinHeight: CGFloat = 92

    static let listCardHorizontalInset: CGFloat = 16
    static let listCardVerticalInset: CGFloat = 6
    static let listContentInset: CGFloat = 14
    static let listVerticalSpacing: CGFloat = 7
    static let listPhotoToLocationSpacing: CGFloat = 9
    static let listTitleToPreviewSpacing: CGFloat = 5
    static let listCollageHeightScale: CGFloat = 0.84
    static let listCollageMaxHeight: CGFloat = 225
    static let listCollageMinHeight: CGFloat = 162
}
