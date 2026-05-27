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
    private var timelineCoordinator: TimelineCoordinator?

    init(window: UIWindow, locator: ServiceLocator = .shared) {
        self.window = window
        self.locator = locator
    }

    func start() {
        let getCurrentUser = locator.resolve(GetCurrentUserUseCase.self)
        if getCurrentUser.execute() != nil {
            showMainApp()
        } else {
            showOnboarding()
        }
        window.makeKeyAndVisible()
    }

    // MARK: - Routing

    func showMainApp() {
        let tabBarController = makeMainTabBar()
        setRoot(tabBarController)
    }

    func showOnboarding() {
        let completeOnboarding = locator.resolve(CompleteOnboardingUseCase.self)
        let getCatalogPlaces = locator.resolve(GetCatalogPlacesUseCase.self)
        let viewModel = OnboardingViewModel(completeOnboarding: completeOnboarding)
        viewModel.onCompleted = { [weak self] in
            self?.handleOnboardingCompleted()
        }
        let viewController = OnboardingViewController(
            viewModel: viewModel,
            getCatalogPlaces: getCatalogPlaces
        )
        let nav = UINavigationController(rootViewController: viewController)
        nav.setNavigationBarHidden(true, animated: false)
        setRoot(nav)
    }

    func handleOnboardingCompleted() {
        // Sync AuthUser.name → ProfileUserSettings so ProfileDetails screen is consistent.
        if let user = locator.resolve(GetCurrentUserUseCase.self).execute() {
            ProfileUserSettings.saveName(user.name)
        }
        showMainApp()
    }

    func handleLogout() {
        let logout = locator.resolve(LogoutUseCase.self)
        logout.execute()
        mapCoordinator = nil
        showOnboarding()
    }

    // MARK: - Private

    private func makeMainTabBar() -> MainTabBarController {
        let tabBarController = MainTabBarController()

        let wishlistNav = makeWishlistNav()
        let statisticsNav = makeStatisticsNav()
        let profileNav = makeProfileNav()

        let timelineNav = UINavigationController()
        timelineNav.tabBarItem = UITabBarItem(
            title: L10n.Tab.timeline,
            image: UIImage(systemName: "clock"),
            selectedImage: UIImage(systemName: "clock")
        )
        let timelineCoordinator = TimelineCoordinator(navigationController: timelineNav, locator: locator)
        timelineCoordinator.start()
        self.timelineCoordinator = timelineCoordinator

        let mapNav = UINavigationController()
        mapNav.tabBarItem = UITabBarItem(
            title: L10n.Common.map,
            image: UIImage(systemName: "globe.europe.africa"),
            selectedImage: UIImage(systemName: "globe.europe.africa")
        )

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
        return tabBarController
    }

    private func setRoot(_ viewController: UIViewController) {
        guard window.rootViewController !== viewController else { return }

        if window.rootViewController == nil {
            window.rootViewController = viewController
        } else {
            UIView.transition(
                with: window,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: { self.window.rootViewController = viewController }
            )
        }
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

    private func makeStatisticsNav() -> UINavigationController {
        let viewModel = StatisticsViewModel(
            getStatisticsUseCase: locator.resolve(GetStatisticsUseCase.self)
        )
        let viewController = StatisticsViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: viewController)
        nav.tabBarItem = UITabBarItem(
            title: L10n.Tab.statistics,
            image: UIImage(systemName: "chart.bar.xaxis"),
            selectedImage: UIImage(systemName: "chart.bar.xaxis")
        )
        return nav
    }

    private func makePlaceholderNav(title: String, systemImageName: String) -> UINavigationController {
        let viewController = PlaceholderViewController(displayTitle: title)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: systemImageName),
            selectedImage: UIImage(systemName: systemImageName)
        )
        return navigationController
    }

    private func makeProfileNav() -> UINavigationController {
        let viewModel = ProfileViewModel(
            getCurrentUser: locator.resolve(GetCurrentUserUseCase.self),
            updateCurrentUser: locator.resolve(UpdateCurrentUserUseCase.self)
        )
        let viewController = ProfileViewController(viewModel: viewModel)
        viewController.onLogout = { [weak self] in
            self?.handleLogout()
        }
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.tabBarItem = UITabBarItem(
            title: L10n.Profile.Tab.title,
            image: UIImage(systemName: "gear"),
            selectedImage: UIImage(systemName: "gear")
        )
        return navigationController
    }
}
