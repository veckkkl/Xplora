//
//  SceneDelegate.swift
//  Xplora
//
//  Created by valentina balde on 11/17/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?
    
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        configureDependencies()
        
        let coordinator = AppCoordinator(window: window, locator: ServiceLocator.shared)
        self.appCoordinator = coordinator
        coordinator.start()
    }

    private func configureDependencies() {
        let locator = ServiceLocator.shared
        let storage: LocalStorageProtocol = LocalStorage()

        // Repositories
        let tripsRepo: TripsRepo = TripsRepoImpl(storage: storage)
        let placesRepo: PlacesRepo = PlacesRepoImpl(storage: storage)
        let settingsRepo: SettingsRepo = SettingsRepoImpl(storage: storage)
        let markersRepo: CountryVisitMarkersRepo = CountryVisitMarkersRepoImpl()
        let notesRepo: NotesRepo = NotesRepoImpl()

        locator.register(TripsRepo.self, instance: tripsRepo)
        locator.register(PlacesRepo.self, instance: placesRepo)
        locator.register(SettingsRepo.self, instance: settingsRepo)
        locator.register(CountryVisitMarkersRepo.self, instance: markersRepo)
        locator.register(NotesRepo.self, instance: notesRepo)

        // Services
        let locationService: LocationService = LocationServiceImpl()
        let fogLogicService: FogLogicService = FogLogicServiceImpl()
        let fogOverlayProvider: FogOverlayProviding = EmptyFogOverlayProvider()

        locator.register(LocationService.self, instance: locationService)
        locator.register(FogLogicService.self, instance: fogLogicService)
        locator.register(FogOverlayProviding.self, instance: fogOverlayProvider)

        // UseCases
        let getVisitedCountriesUseCase: GetVisitedCountriesUseCase =
            GetVisitedCountriesUseCaseImpl(placesRepo: placesRepo)

        let getTripsTimelineUseCase: GetTripsTimelineUseCase =
            GetTripsTimelineUseCaseImpl(tripsRepo: tripsRepo)

        let addVisitedPlaceUseCase: AddVisitedPlaceUseCase =
            AddVisitedPlaceUseCaseImpl(placesRepo: placesRepo)

        let getCountryVisitMarkersUseCase: GetCountryVisitMarkersUseCase =
            GetCountryVisitMarkersUseCaseImpl(markersRepo: markersRepo)

        locator.register(GetVisitedCountriesUseCase.self, instance: getVisitedCountriesUseCase)
        locator.register(GetTripsTimelineUseCase.self, instance: getTripsTimelineUseCase)
        locator.register(AddVisitedPlaceUseCase.self, instance: addVisitedPlaceUseCase)
        locator.register(GetCountryVisitMarkersUseCase.self, instance: getCountryVisitMarkersUseCase)

        let getNoteUseCase: GetNoteUseCase = GetNoteUseCaseImpl(notesRepo: notesRepo)
        let saveNoteUseCase: SaveNoteUseCase = SaveNoteUseCaseImpl(notesRepo: notesRepo)
        let deleteNoteUseCase: DeleteNoteUseCase = DeleteNoteUseCaseImpl(notesRepo: notesRepo)

        locator.register(GetNoteUseCase.self, instance: getNoteUseCase)
        locator.register(SaveNoteUseCase.self, instance: saveNoteUseCase)
        locator.register(DeleteNoteUseCase.self, instance: deleteNoteUseCase)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see application:didDiscardSceneSessions instead).
    }
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

