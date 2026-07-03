//
//  AppDependenciesConfigurator.swift
//  Xplora
//

/// Registers the application's dependency graph into the `ServiceLocator`.
///
/// `ServiceLocator` stores and resolves dependencies; this configurator is the
/// single place that wires concrete repositories, services and use cases to
/// their abstractions. It must run before the `AppCoordinator` is started.
enum AppDependenciesConfigurator {
    static func configure(_ locator: ServiceLocator) {
        let storage: LocalStorageProtocol = LocalStorage()
        let coreDataStack = CoreDataStack()

        // Repositories
        let tripsRepo: TripsRepo = TripsRepoImpl(storage: storage)
        let settingsRepo: SettingsRepo = SettingsRepoImpl(storage: storage)
        let notesRepo: NotesRepo = NotesRepoImpl(coreDataStack: coreDataStack)
        let authRepository: AuthRepository = AuthRepositoryImpl(storage: storage)
        let wishlistRepo: WishlistRepo = WishlistRepoImpl(storage: storage)

        locator.register(TripsRepo.self, instance: tripsRepo)
        locator.register(SettingsRepo.self, instance: settingsRepo)
        locator.register(NotesRepo.self, instance: notesRepo)
        locator.register(AuthRepository.self, instance: authRepository)
        locator.register(WishlistRepo.self, instance: wishlistRepo)

        // Services
        let locationService: LocationService = LocationServiceImpl()
        let fogOverlayProvider: FogOverlayProviding = EmptyFogOverlayProvider()

        locator.register(LocationService.self, instance: locationService)
        locator.register(FogOverlayProviding.self, instance: fogOverlayProvider)

        // UseCases
        let validateTripDateRangeUseCase: ValidateTripDateRangeUseCase =
            ValidateTripDateRangeUseCaseImpl()

        let getTripsUseCase: GetTripsUseCase =
            GetTripsUseCaseImpl(tripsRepo: tripsRepo)

        let createTripUseCase: CreateTripUseCase =
            CreateTripUseCaseImpl(tripsRepo: tripsRepo, validateDates: validateTripDateRangeUseCase)

        let updateTripDatesUseCase: UpdateTripDatesUseCase =
            UpdateTripDatesUseCaseImpl(tripsRepo: tripsRepo, validateDates: validateTripDateRangeUseCase)

        let deleteTripUseCase: DeleteTripUseCase =
            DeleteTripUseCaseImpl(tripsRepo: tripsRepo)

        let tripNotesCountProvider: TripNotesCountProviding =
            NoteLocationTripNotesCountProvider()

        locator.register(ValidateTripDateRangeUseCase.self, instance: validateTripDateRangeUseCase)
        locator.register(GetTripsUseCase.self, instance: getTripsUseCase)
        locator.register(CreateTripUseCase.self, instance: createTripUseCase)
        locator.register(UpdateTripDatesUseCase.self, instance: updateTripDatesUseCase)
        locator.register(DeleteTripUseCase.self, instance: deleteTripUseCase)
        locator.register(TripNotesCountProviding.self, instance: tripNotesCountProvider)

        let getNoteUseCase: GetNoteUseCase = GetNoteUseCaseImpl(notesRepo: notesRepo)
        let getAllNotesUseCase: GetAllNotesUseCase = GetAllNotesUseCaseImpl(notesRepo: notesRepo)
        let saveNoteUseCase: SaveNoteUseCase = SaveNoteUseCaseImpl(notesRepo: notesRepo)
        let deleteNoteUseCase: DeleteNoteUseCase = DeleteNoteUseCaseImpl(notesRepo: notesRepo)

        locator.register(GetNoteUseCase.self, instance: getNoteUseCase)
        locator.register(GetAllNotesUseCase.self, instance: getAllNotesUseCase)
        locator.register(SaveNoteUseCase.self, instance: saveNoteUseCase)
        locator.register(DeleteNoteUseCase.self, instance: deleteNoteUseCase)

        // Auth use cases
        let getCurrentUserUseCase: GetCurrentUserUseCase =
            GetCurrentUserUseCaseImpl(authRepository: authRepository)
        let completeOnboardingUseCase: CompleteOnboardingUseCase =
            CompleteOnboardingUseCaseImpl(authRepository: authRepository)
        let updateCurrentUserUseCase: UpdateCurrentUserUseCase =
            UpdateCurrentUserUseCaseImpl(authRepository: authRepository)
        let logoutUseCase: LogoutUseCase =
            LogoutUseCaseImpl(authRepository: authRepository)
        let resetUserDataUseCase: ResetUserDataUseCase =
            ResetUserDataUseCaseImpl(
                logout: logoutUseCase,
                tripsRepo: tripsRepo,
                wishlistRepo: wishlistRepo,
                notesRepo: notesRepo
            )

        locator.register(GetCurrentUserUseCase.self, instance: getCurrentUserUseCase)
        locator.register(CompleteOnboardingUseCase.self, instance: completeOnboardingUseCase)
        locator.register(UpdateCurrentUserUseCase.self, instance: updateCurrentUserUseCase)
        locator.register(LogoutUseCase.self, instance: logoutUseCase)
        locator.register(ResetUserDataUseCase.self, instance: resetUserDataUseCase)

        // Wishlist
        let getWishlistUseCase: GetWishlistCountriesUseCase = GetWishlistCountriesUseCaseImpl(repo: wishlistRepo)
        let addWishlistUseCase: AddWishlistCountryUseCase = AddWishlistCountryUseCaseImpl(repo: wishlistRepo)
        let removeWishlistUseCase: RemoveWishlistCountryUseCase = RemoveWishlistCountryUseCaseImpl(repo: wishlistRepo)
        let toggleWishlistUseCase: ToggleWishlistCountryUseCase = ToggleWishlistCountryUseCaseImpl(repo: wishlistRepo)

        locator.register(GetWishlistCountriesUseCase.self, instance: getWishlistUseCase)
        locator.register(AddWishlistCountryUseCase.self, instance: addWishlistUseCase)
        locator.register(RemoveWishlistCountryUseCase.self, instance: removeWishlistUseCase)
        locator.register(ToggleWishlistCountryUseCase.self, instance: toggleWishlistUseCase)

        // Place catalog. The source of truth is `CatalogPlacePolicy`; the API
        // client refreshes the cache in the background as a validation step.
        let countriesAPIClient: CountriesAPIClient = CountriesNowAPIClient()
        let catalogPlacesRepo: CatalogPlacesRepo =
            CatalogPlacesRepoImpl(api: countriesAPIClient, storage: storage)
        let getCatalogPlacesUseCase: GetCatalogPlacesUseCase =
            GetCatalogPlacesUseCaseImpl(repo: catalogPlacesRepo)

        locator.register(CatalogPlacesRepo.self, instance: catalogPlacesRepo)
        locator.register(GetCatalogPlacesUseCase.self, instance: getCatalogPlacesUseCase)

        let getStatisticsUseCase: GetStatisticsUseCase = GetStatisticsUseCaseImpl(
            getCatalogPlaces: getCatalogPlacesUseCase,
            getTrips: getTripsUseCase
        )
        locator.register(GetStatisticsUseCase.self, instance: getStatisticsUseCase)

        // Cities catalog (bundled, gated by CatalogPlacePolicy)
        let citiesCatalogRepo: CitiesCatalogRepo = CitiesCatalogRepoImpl()
        let getCitiesForPlaceUseCase: GetCitiesForPlaceUseCase =
            GetCitiesForPlaceUseCaseImpl(repo: citiesCatalogRepo)
        let searchCitiesUseCase: SearchCitiesUseCase =
            SearchCitiesUseCaseImpl(repo: citiesCatalogRepo)

        locator.register(CitiesCatalogRepo.self, instance: citiesCatalogRepo)
        locator.register(GetCitiesForPlaceUseCase.self, instance: getCitiesForPlaceUseCase)
        locator.register(SearchCitiesUseCase.self, instance: searchCitiesUseCase)
    }
}
