//
//  TimelineCoordinator.swift
//  Xplora
//

import UIKit

@MainActor
final class TimelineCoordinator {
    private let navigationController: UINavigationController
    private let locator: ServiceLocator
    private weak var timelineViewModel: TimelineViewModel?
    private weak var presentedNavigationController: UINavigationController?

    init(navigationController: UINavigationController, locator: ServiceLocator = .shared) {
        self.navigationController = navigationController
        self.locator = locator
    }

    func start() {
        let getTripsUseCase: GetTripsUseCase = locator.resolve(GetTripsUseCase.self)
        let getCatalogPlaces: GetCatalogPlacesUseCase = locator.resolve(GetCatalogPlacesUseCase.self)
        let deleteTripUseCase: DeleteTripUseCase = locator.resolve(DeleteTripUseCase.self)
        let viewModel = TimelineViewModel(
            getTripsUseCase: getTripsUseCase,
            getCatalogPlaces: getCatalogPlaces,
            deleteTripUseCase: deleteTripUseCase
        )
        let viewController = TimelineViewController(viewModel: viewModel)

        viewModel.onRoute = { [weak self] route in
            self?.handle(route)
        }

        navigationController.viewControllers = [viewController]
        timelineViewModel = viewModel
    }

    private func handle(_ route: TimelineRoute) {
        switch route {
        case .addTrip:
            presentCountryPicker()
        case let .editTripDates(tripId, place, startDate, endDate):
            presentDateRange(
                mode: .edit(
                    tripId: tripId,
                    place: place,
                    startDate: startDate,
                    endDate: endDate
                )
            )
        }
    }

    private func presentCountryPicker() {
        let getCatalogPlaces: GetCatalogPlacesUseCase = locator.resolve(GetCatalogPlacesUseCase.self)
        let viewModel = TripCountryPickerViewModel(getCatalogPlaces: getCatalogPlaces)
        viewModel.output = self

        let viewController = TripCountryPickerViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: viewController)
        nav.modalPresentationStyle = .formSheet

        presentedNavigationController = nav
        navigationController.present(nav, animated: true)
    }

    private func presentDateRange(mode: TripDateRangeMode) {
        let createTrip: CreateTripUseCase = locator.resolve(CreateTripUseCase.self)
        let updateTripDates: UpdateTripDatesUseCase = locator.resolve(UpdateTripDatesUseCase.self)
        let validateDates: ValidateTripDateRangeUseCase = locator.resolve(ValidateTripDateRangeUseCase.self)

        let viewModel = TripDateRangeViewModel(
            mode: mode,
            createTrip: createTrip,
            updateTripDates: updateTripDates,
            validateDates: validateDates
        )
        viewModel.output = self

        let viewController = TripDateRangeViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: viewController)
        nav.modalPresentationStyle = .formSheet

        presentedNavigationController = nav
        navigationController.present(nav, animated: true)
    }
}

extension TimelineCoordinator: TripCountryPickerModuleOutput {
    func tripCountryPickerDidSelect(place: CatalogPlace) {
        let createTrip: CreateTripUseCase = locator.resolve(CreateTripUseCase.self)
        let updateTripDates: UpdateTripDatesUseCase = locator.resolve(UpdateTripDatesUseCase.self)
        let validateDates: ValidateTripDateRangeUseCase = locator.resolve(ValidateTripDateRangeUseCase.self)

        let viewModel = TripDateRangeViewModel(
            mode: .create(place: place),
            createTrip: createTrip,
            updateTripDates: updateTripDates,
            validateDates: validateDates
        )
        viewModel.output = self

        let viewController = TripDateRangeViewController(viewModel: viewModel)
        presentedNavigationController?.pushViewController(viewController, animated: true)
    }

    func tripCountryPickerDidCancel() {
        presentedNavigationController?.dismiss(animated: true)
    }
}

extension TimelineCoordinator: TripDateRangeModuleOutput {
    func tripDateRangeDidSave(tripId: UUID) {
        presentedNavigationController?.dismiss(animated: true) { [weak self] in
            self?.timelineViewModel?.refresh()
        }
    }

    func tripDateRangeDidCancel() {
        if let nav = presentedNavigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            presentedNavigationController?.dismiss(animated: true)
        }
    }
}
