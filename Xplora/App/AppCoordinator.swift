//
//  AppCoordinator.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//

import UIKit

@MainActor
final class AppCoordinator {
    private let window: UIWindow
    private let locator: ServiceLocator
    private var mapCoordinator: MapCoordinator?
    
    init(window: UIWindow, locator: ServiceLocator = .shared) {
        self.window = window
        self.locator = locator
    }
    
    @MainActor
    func start() {
        let tabBarController = MainTabBarController()

        let wishlistNav = makePlaceholderNav(title: "Wishlist", systemImageName: "heart")
        let timelineNav = makePlaceholderNav(title: "Timeline", systemImageName: "clock")
        let statisticsNav = makePlaceholderNav(title: "Statistics", systemImageName: "chart.bar.xaxis")
        let profileNav = makeProfileNav()

        let mapNav = UINavigationController()
        mapNav.tabBarItem = UITabBarItem(title: "Map", image: UIImage(systemName: "globe.europe.africa"), selectedImage: UIImage(systemName: "globe.europe.africa"))

        let mapCoordinator = MapCoordinator(navigationController: mapNav, locator: locator)
        mapCoordinator.start()
        self.mapCoordinator = mapCoordinator

        tabBarController.viewControllers = [
            wishlistNav,
            timelineNav,
            mapNav,
            statisticsNav,
            profileNav
        ]
        tabBarController.selectedIndex = 2
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }

    private func makePlaceholderNav(title: String, systemImageName: String) -> UINavigationController {
        let viewController = PlaceholderViewController(displayTitle: title)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: systemImageName), selectedImage: UIImage(systemName: systemImageName))
        return navigationController
    }

    private func makeProfileNav() -> UINavigationController {
        let viewModel = ProfileViewModel()
        let viewController = ProfileViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.tabBarItem = UITabBarItem(
            title: L10n.Profile.tabTitle,
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle")
        )
        return navigationController
    }

}
