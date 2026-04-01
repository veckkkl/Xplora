//
//  TripPhotoCollageLayoutEngine.swift
//  Xplora
//

import UIKit

enum TripPhotoCollageDisplayMode {
    case preview
    case noteFull
}

struct TripPhotoCollageDisplayedItem: Hashable {
    let sourceIndex: Int
    let overflowCount: Int?
}

enum TripPhotoCollageLayoutEngine {
    private static let maxNoteFullDisplayedItems = 10

    private enum LayoutCase {
        case one
        case two
        case three
        case four
        case five
        case six
        case seven
        case eight
        case nine
        case ten
    }

    private enum HeightVariant {
        case a
        case b

        var multiplier: CGFloat {
            switch self {
            case .a:
                return 1.0
            case .b:
                return 1.5
            }
        }
    }

    private struct TileFrame {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
    }

    static func displayedItems(totalCount: Int, mode: TripPhotoCollageDisplayMode) -> [TripPhotoCollageDisplayedItem] {
        guard totalCount > 0 else { return [] }

        switch mode {
        case .noteFull:
            let displayedCount = min(totalCount, maxNoteFullDisplayedItems)
            return (0..<displayedCount).map { index in
                TripPhotoCollageDisplayedItem(sourceIndex: index, overflowCount: nil)
            }
        case .preview:
            if totalCount >= 10 {
                return Array(0..<5).map { index in
                    let overflowCount = index == 4 ? totalCount - 5 : nil
                    return TripPhotoCollageDisplayedItem(sourceIndex: index, overflowCount: overflowCount)
                }
            }

            return (0..<totalCount).map { index in
                TripPhotoCollageDisplayedItem(sourceIndex: index, overflowCount: nil)
            }
        }
    }

    static func preferredHeight(
        forWidth width: CGFloat,
        displayedCount: Int,
        mode: TripPhotoCollageDisplayMode,
        hasOverflowBadge: Bool
    ) -> CGFloat {
        guard width > 0, displayedCount > 0 else { return 0 }

        let layoutCase = resolveLayoutCase(
            displayedCount: displayedCount,
            mode: mode,
            hasOverflowBadge: hasOverflowBadge
        )
        let variant = heightVariant(for: layoutCase, mode: mode, hasOverflowBadge: hasOverflowBadge)
        return width * variant.multiplier
    }

    static func makeLayout(
        displayedCount: Int,
        mode: TripPhotoCollageDisplayMode,
        hasOverflowBadge: Bool
    ) -> UICollectionViewLayout {
        let spacing: CGFloat = mode == .preview ? 2 : 3
        let layoutCase = resolveLayoutCase(
            displayedCount: displayedCount,
            mode: mode,
            hasOverflowBadge: hasOverflowBadge
        )
        let frames = frames(for: layoutCase)

        return UICollectionViewCompositionalLayout { _, _ in
            let group = NSCollectionLayoutGroup.custom(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
            ) { groupEnvironment in
                let containerSize = groupEnvironment.container.effectiveContentSize
                return customItems(
                    for: frames,
                    in: containerSize,
                    spacing: spacing
                )
            }

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .zero
            return section
        }
    }

    private static func resolveLayoutCase(
        displayedCount: Int,
        mode: TripPhotoCollageDisplayMode,
        hasOverflowBadge: Bool
    ) -> LayoutCase {
        switch mode {
        case .preview:
            if hasOverflowBadge {
                return .five
            }

            switch displayedCount {
            case ..<2: return .one
            case 2: return .two
            case 3: return .three
            case 4: return .four
            case 5: return .five
            case 6: return .six
            case 7: return .seven
            case 8: return .eight
            default: return .nine
            }
        case .noteFull:
            switch displayedCount {
            case ..<2: return .one
            case 2: return .two
            case 3: return .three
            case 4: return .four
            case 5: return .five
            case 6: return .six
            case 7: return .seven
            case 8: return .eight
            case 9: return .nine
            default: return .ten
            }
        }
    }

    private static func heightVariant(
        for layoutCase: LayoutCase,
        mode: TripPhotoCollageDisplayMode,
        hasOverflowBadge: Bool
    ) -> HeightVariant {
        if mode == .preview && hasOverflowBadge {
            return .a
        }

        switch layoutCase {
        case .one:
            return .b
        case .two, .three, .four, .five:
            return .a
        case .six, .seven, .eight, .nine, .ten:
            return .b
        }
    }
}

private extension TripPhotoCollageLayoutEngine {
    private static func frames(for layoutCase: LayoutCase) -> [TileFrame] {
        switch layoutCase {
        case .one:
            return [TileFrame(x: 0, y: 0, width: 1, height: 1)]
        case .two:
            return [
                TileFrame(x: 0, y: 0, width: 0.5, height: 1),
                TileFrame(x: 0.5, y: 0, width: 0.5, height: 1)
            ]
        case .three:
            return [
                TileFrame(x: 0, y: 0, width: 0.5, height: 1),
                TileFrame(x: 0.5, y: 0, width: 0.25, height: 1),
                TileFrame(x: 0.75, y: 0, width: 0.25, height: 1)
            ]
        case .four:
            return [
                TileFrame(x: 0, y: 0, width: 0.5, height: 1),
                TileFrame(x: 0.5, y: 0, width: 0.25, height: 0.5),
                TileFrame(x: 0.5, y: 0.5, width: 0.25, height: 0.5),
                TileFrame(x: 0.75, y: 0, width: 0.25, height: 1)
            ]
        case .five:
            return [
                TileFrame(x: 0, y: 0, width: 0.5, height: 1),
                TileFrame(x: 0.5, y: 0, width: 0.25, height: 0.5),
                TileFrame(x: 0.75, y: 0, width: 0.25, height: 0.5),
                TileFrame(x: 0.5, y: 0.5, width: 0.25, height: 0.5),
                TileFrame(x: 0.75, y: 0.5, width: 0.25, height: 0.5)
            ]
        case .six:
            return [
                TileFrame(x: 0, y: 0, width: 0.5, height: 2.0 / 3.0),
                TileFrame(x: 0, y: 2.0 / 3.0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.25, y: 2.0 / 3.0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.5, y: 0, width: 0.5, height: 1.0 / 3.0),
                TileFrame(x: 0.5, y: 1.0 / 3.0, width: 0.25, height: 2.0 / 3.0),
                TileFrame(x: 0.75, y: 1.0 / 3.0, width: 0.25, height: 2.0 / 3.0)
            ]
        case .seven:
            return [
                TileFrame(x: 0, y: 0, width: 0.5, height: 2.0 / 3.0),
                TileFrame(x: 0, y: 2.0 / 3.0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.25, y: 2.0 / 3.0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.5, y: 0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.75, y: 0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.5, y: 1.0 / 3.0, width: 0.25, height: 2.0 / 3.0),
                TileFrame(x: 0.75, y: 1.0 / 3.0, width: 0.25, height: 2.0 / 3.0)
            ]
        case .eight:
            return [
                TileFrame(x: 0, y: 0, width: 0.5, height: 2.0 / 3.0),
                TileFrame(x: 0, y: 2.0 / 3.0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.25, y: 2.0 / 3.0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.5, y: 0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.75, y: 0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.5, y: 1.0 / 3.0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.5, y: 2.0 / 3.0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.75, y: 1.0 / 3.0, width: 0.25, height: 2.0 / 3.0)
            ]
        case .nine:
            return [
                TileFrame(x: 0, y: 0, width: 0.5, height: 2.0 / 3.0),
                TileFrame(x: 0, y: 2.0 / 3.0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.25, y: 2.0 / 3.0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.5, y: 0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.75, y: 0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.5, y: 1.0 / 3.0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.75, y: 1.0 / 3.0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.5, y: 2.0 / 3.0, width: 0.25, height: 1.0 / 3.0),
                TileFrame(x: 0.75, y: 2.0 / 3.0, width: 0.25, height: 1.0 / 3.0)
            ]
        case .ten:
            return [
                TileFrame(x: 0, y: 0, width: 0.5, height: 0.5),
                TileFrame(x: 0.5, y: 0, width: 0.25, height: 0.25),
                TileFrame(x: 0.75, y: 0, width: 0.25, height: 0.25),
                TileFrame(x: 0.5, y: 0.25, width: 0.25, height: 0.25),
                TileFrame(x: 0.75, y: 0.25, width: 0.25, height: 0.25),
                TileFrame(x: 0, y: 0.5, width: 0.25, height: 0.25),
                TileFrame(x: 0.25, y: 0.5, width: 0.25, height: 0.25),
                TileFrame(x: 0, y: 0.75, width: 0.25, height: 0.25),
                TileFrame(x: 0.25, y: 0.75, width: 0.25, height: 0.25),
                TileFrame(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
            ]
        }
    }

    private static func customItems(
        for frames: [TileFrame],
        in containerSize: CGSize,
        spacing: CGFloat
    ) -> [NSCollectionLayoutGroupCustomItem] {
        guard containerSize.width > 0, containerSize.height > 0 else { return [] }
        let halfSpacing = spacing * 0.5
        let epsilon: CGFloat = 0.0001

        return frames.map { frame in
            let rawRect = CGRect(
                x: frame.x * containerSize.width,
                y: frame.y * containerSize.height,
                width: frame.width * containerSize.width,
                height: frame.height * containerSize.height
            )

            let touchesLeftEdge = frame.x <= epsilon
            let touchesTopEdge = frame.y <= epsilon
            let touchesRightEdge = (frame.x + frame.width) >= (1 - epsilon)
            let touchesBottomEdge = (frame.y + frame.height) >= (1 - epsilon)

            var insetLeft = touchesLeftEdge ? 0 : halfSpacing
            var insetRight = touchesRightEdge ? 0 : halfSpacing
            var insetTop = touchesTopEdge ? 0 : halfSpacing
            var insetBottom = touchesBottomEdge ? 0 : halfSpacing

            let horizontalInsets = insetLeft + insetRight
            if horizontalInsets >= rawRect.width, horizontalInsets > 0 {
                let scale = rawRect.width / horizontalInsets
                insetLeft *= scale
                insetRight *= scale
            }

            let verticalInsets = insetTop + insetBottom
            if verticalInsets >= rawRect.height, verticalInsets > 0 {
                let scale = rawRect.height / verticalInsets
                insetTop *= scale
                insetBottom *= scale
            }

            let rect = CGRect(
                x: rawRect.minX + insetLeft,
                y: rawRect.minY + insetTop,
                width: max(0, rawRect.width - insetLeft - insetRight),
                height: max(0, rawRect.height - insetTop - insetBottom)
            )

            return NSCollectionLayoutGroupCustomItem(
                frame: rect
            )
        }
    }
}
