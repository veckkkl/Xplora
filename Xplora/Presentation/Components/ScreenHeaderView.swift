//
//  ScreenHeaderView.swift
//  Xplora
//

import SnapKit
import UIKit

enum AppTypography {
    static func screenTitle() -> UIFont {
        UIFont.systemFont(ofSize: AppSpacing.screenTitleFontSize, weight: .bold)
    }
}

enum AppSpacing {
    static let screenTitleFontSize: CGFloat = 36
    static let screenHorizontalInset: CGFloat = 20
    // Titles sit `statusBar + screenTitleTopInset` from the top (the nav bar is
    // cancelled from the safe area). Kept large enough that the title clears the
    // iOS 26 glass backdrop the bar draws behind a "+" bar button (~44pt).
    static let screenTitleTopInset: CGFloat = 44
    static let screenTitleBottomInset: CGFloat = 14
}

/// Large bold left-aligned screen title that matches the Settings screen.
/// Designed to be embedded as the FIRST element of scrollable content
/// (table header, stack arranged subview, or collection cell) so it scrolls
/// away with the content like the Settings screen title.
@MainActor
final class ScreenHeaderView: UIView {
    private let titleLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        setupView()
        titleLabel.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear

        titleLabel.font = AppTypography.screenTitle()
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(AppSpacing.screenHorizontalInset)
            make.trailing.lessThanOrEqualToSuperview().inset(AppSpacing.screenHorizontalInset)
            make.top.equalToSuperview().inset(AppSpacing.screenTitleTopInset)
            make.bottom.equalToSuperview().inset(AppSpacing.screenTitleBottomInset)
        }
    }
}

extension UIViewController {
    /// Root tab screens render the big title as the first scrollable content
    /// element while keeping a transparent, title-less navigation bar only for
    /// the system bar button (e.g. "+"). The empty navigation bar would
    /// otherwise reserve ~44pt above the title. Cancel that height from the top
    /// safe area so the title sits just below the status bar — a single shared
    /// source of truth for every root screen. Call from `viewDidLayoutSubviews`.
    func adjustTopInsetForScrollingScreenTitle() {
        let navigationBarHeight = navigationController?.navigationBar.frame.height ?? 0
        let target = -navigationBarHeight
        if additionalSafeAreaInsets.top != target {
            additionalSafeAreaInsets.top = target
        }
    }

    /// A root tab screen that carries a system bar button (e.g. "+") otherwise
    /// gets an iOS 26 Liquid Glass backdrop drawn behind the whole navigation
    /// bar, which grays out the custom scrollable title. Force a fully
    /// transparent bar at BOTH the per-VC (`navigationItem`) and the shared
    /// (`navigationController.navigationBar`) level so only the button keeps its
    /// native glass while the title stays clean — like the bar-button-less
    /// screens (Statistics / Settings). Apply in `viewWillAppear`.
    func applyTransparentNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil
        appearance.shadowColor = .clear

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance

        if let navigationBar = navigationController?.navigationBar {
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
            navigationBar.isTranslucent = true
        }
    }

    /// Restore a standard bar background so pushed screens that share this
    /// navigation controller's bar aren't left transparent. Call in
    /// `viewWillDisappear`.
    func restoreDefaultNavigationBarBackground() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }
}

