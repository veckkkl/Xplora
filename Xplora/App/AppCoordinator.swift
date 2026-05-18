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

        let wishlistNav = makeWishlistNav()
        let timelineNav = makePlaceholderNav(title: L10n.Tab.timeline, systemImageName: "clock")
        let statisticsNav = makePlaceholderNav(title: L10n.Tab.statistics, systemImageName: "chart.bar.xaxis")
        let profileNav = makeProfileNav()

        let mapNav = UINavigationController()
        mapNav.tabBarItem = UITabBarItem(title: L10n.Common.map, image: UIImage(systemName: "globe.europe.africa"), selectedImage: UIImage(systemName: "globe.europe.africa"))

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

    private func makeWishlistNav() -> UINavigationController {
        let getUseCase: GetWishlistCountriesUseCase = locator.resolve(GetWishlistCountriesUseCase.self)
        let addUseCase: AddWishlistCountryUseCase = locator.resolve(AddWishlistCountryUseCase.self)
        let removeUseCase: RemoveWishlistCountryUseCase = locator.resolve(RemoveWishlistCountryUseCase.self)
        let toggleUseCase: ToggleWishlistCountryUseCase = locator.resolve(ToggleWishlistCountryUseCase.self)
        let getCatalogPlacesUseCase: GetCatalogPlacesUseCase = locator.resolve(GetCatalogPlacesUseCase.self)
        let getCitiesForPlaceUseCase: GetCitiesForPlaceUseCase = locator.resolve(GetCitiesForPlaceUseCase.self)

        let viewModel = WishlistViewModel(
            getUseCase: getUseCase,
            addUseCase: addUseCase,
            removeUseCase: removeUseCase,
            toggleUseCase: toggleUseCase
        )
        let viewController = WishlistViewController(
            viewModel: viewModel,
            getCatalogPlacesUseCase: getCatalogPlacesUseCase,
            getCitiesForPlaceUseCase: getCitiesForPlaceUseCase
        )
        let nav = UINavigationController(rootViewController: viewController)
        nav.tabBarItem = UITabBarItem(
            title: L10n.Tab.wishlist,
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )
        return nav
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
            title: L10n.Profile.Tab.title,
            image: UIImage(systemName: "gear"),
            selectedImage: UIImage(systemName: "gear")
        )
        return navigationController
    }

}
