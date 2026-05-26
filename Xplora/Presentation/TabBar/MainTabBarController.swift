//
//  MainTabBarController.swift
//  Xplora

import UIKit

final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
    }

    private func configureAppearance() {
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.selected.iconColor = .systemBlue
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        itemAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.55)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.55)
        ]

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(white: 0.13, alpha: 1.0)
        appearance.shadowColor = .clear
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = UIColor.white.withAlphaComponent(0.55)
    }
}
