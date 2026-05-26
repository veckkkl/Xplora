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
        let deleteTripUseCase: DeleteTripUseCase = locator.resolve(DeleteTripUseCase.self)
        let viewModel = TimelineViewModel(
            getTripsUseCase: getTripsUseCase,
            deleteTripUseCase: deleteTripUseCase
        )
        let viewController = TimelineViewController(viewModel: viewModel)

        viewModel.onRoute = { [weak self] route in
            self?.handle(route)
        }

        navigationController.viewControllers = [viewController]
        timelineViewModel = viewModel
    }

    /// Entry point for the "create trip" flow.
    /// Invoked by the country selection step once it lands; the dates screen
    /// handles trip creation itself via `CreateTripUseCase`.
    func presentCreateTrip(country: Country) {
        presentDateRange(mode: .create(country: country))
    }

    private func handle(_ route: TimelineRoute) {
        switch route {
        case .addTrip:
            presentCountryPicker()
        case let .editTripDates(tripId, country, startDate, endDate):
            presentDateRange(
                mode: .edit(
                    tripId: tripId,
                    country: country,
                    startDate: startDate,
                    endDate: endDate
                )
            )
        }
    }

    private func presentCountryPicker() {
        let getAllCountries: GetAllCountriesUseCase = locator.resolve(GetAllCountriesUseCase.self)
        let viewModel = TripCountryPickerViewModel(getAllCountries: getAllCountries)
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
    func tripCountryPickerDidSelect(country: Country) {
        let createTrip: CreateTripUseCase = locator.resolve(CreateTripUseCase.self)
        let updateTripDates: UpdateTripDatesUseCase = locator.resolve(UpdateTripDatesUseCase.self)
        let validateDates: ValidateTripDateRangeUseCase = locator.resolve(ValidateTripDateRangeUseCase.self)

        let viewModel = TripDateRangeViewModel(
            mode: .create(country: country),
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
