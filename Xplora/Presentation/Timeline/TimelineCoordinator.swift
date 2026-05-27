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
    private weak var pickerViewController: TripCountryPickerViewController?

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
            pushCountryPicker()
        case let .editTripDates(tripId, place, startDate, endDate):
            pushDateRange(
                mode: .edit(
                    tripId: tripId,
                    place: place,
                    startDate: startDate,
                    endDate: endDate
                )
            )
        }
    }

    private func pushCountryPicker() {
        let getCatalogPlaces: GetCatalogPlacesUseCase = locator.resolve(GetCatalogPlacesUseCase.self)
        let viewModel = TripCountryPickerViewModel(getCatalogPlaces: getCatalogPlaces)
        viewModel.output = self

        let viewController = TripCountryPickerViewController(viewModel: viewModel)
        pickerViewController = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    private func pushDateRange(mode: TripDateRangeMode) {
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
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension TimelineCoordinator: TripCountryPickerModuleOutput {
    func tripCountryPickerDidSelect(place: CatalogPlace) {
        pushDateRange(mode: .create(place: place))
    }

    func tripCountryPickerDidCancel() {
        guard let picker = pickerViewController else { return }
        navigationController.popToViewController(picker, animated: false)
        navigationController.popViewController(animated: true)
    }
}

extension TimelineCoordinator: TripDateRangeModuleOutput {
    func tripDateRangeDidSave(tripId: UUID) {
        navigationController.popToRootViewController(animated: true)
        timelineViewModel?.refresh()
    }

    func tripDateRangeDidCancel() {
        navigationController.popViewController(animated: true)
    }
}
