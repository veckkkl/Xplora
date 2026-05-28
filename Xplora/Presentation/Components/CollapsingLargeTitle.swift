//
//  CollapsingLargeTitle.swift
//  Xplora
//

import UIKit

extension UIViewController {
    /// Configures a native Notes-style collapsing large title on the
    /// navigation controller's bar: a big title at the top that scrolls up with
    /// the content and collapses into the inline title bar (with the system
    /// Liquid Glass background) once the content scrolls. System bar buttons
    /// stay intact. Call from `viewDidLoad`/`setup`.
    func configureCollapsingLargeTitle() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()

        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()

        navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
        navigationBar.standardAppearance = standardAppearance
        navigationBar.compactAppearance = standardAppearance
        navigationBar.isTranslucent = true
    }
}
