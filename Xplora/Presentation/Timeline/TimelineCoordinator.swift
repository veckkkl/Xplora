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
    private weak var tripNotesViewModel: NotesListViewModel?
    private lazy var noteRouter: NoteRouter = {
        let builder = NoteModuleBuilder(
            getNoteUseCase: locator.resolve(GetNoteUseCase.self),
            saveNoteUseCase: locator.resolve(SaveNoteUseCase.self),
            deleteNoteUseCase: locator.resolve(DeleteNoteUseCase.self)
        )
        return NoteRouterImpl(navigationController: navigationController, builder: builder)
    }()

    init(navigationController: UINavigationController, locator: ServiceLocator = .shared) {
        self.navigationController = navigationController
        self.locator = locator
    }

    func start() {
        let getTripsUseCase: GetTripsUseCase = locator.resolve(GetTripsUseCase.self)
        let getCatalogPlaces: GetCatalogPlacesUseCase = locator.resolve(GetCatalogPlacesUseCase.self)
        let getAllNotesUseCase: GetAllNotesUseCase = locator.resolve(GetAllNotesUseCase.self)
        let deleteTripUseCase: DeleteTripUseCase = locator.resolve(DeleteTripUseCase.self)
        let tripNotesCountProvider: TripNotesCountProviding = locator.resolve(TripNotesCountProviding.self)
        let viewModel = TimelineViewModel(
            getTripsUseCase: getTripsUseCase,
            getCatalogPlaces: getCatalogPlaces,
            getAllNotesUseCase: getAllNotesUseCase,
            deleteTripUseCase: deleteTripUseCase,
            tripNotesCountProvider: tripNotesCountProvider
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
        case let .showTripNotes(trip, place):
            pushTripNotes(trip: trip, place: place)
        }
    }

    private func pushTripNotes(trip: Trip, place: CatalogPlace) {
        let getAllNotesUseCase: GetAllNotesUseCase = locator.resolve(GetAllNotesUseCase.self)
        let tripNotesCountProvider: TripNotesCountProviding =
            locator.resolve(TripNotesCountProviding.self)
        let deleteNoteUseCase: DeleteNoteUseCase = locator.resolve(DeleteNoteUseCase.self)

        let title = "\(place.flag) \(place.localizedName)"
            .trimmingCharacters(in: .whitespaces)

        let viewModel = NotesListViewModel(
            getAllNotesUseCase: getAllNotesUseCase,
            tripNotesCountProvider: tripNotesCountProvider,
            deleteNoteUseCase: deleteNoteUseCase,
            filter: .trip(trip),
            screenTitle: title
        )
        viewModel.onRoute = { [weak self] route in
            guard let self else { return }
            switch route {
            case .addNew:
                self.noteRouter.showNote(noteId: nil, coordinate: nil, output: self)
            case .open(let noteId):
                self.noteRouter.showNote(noteId: noteId, coordinate: nil, output: self)
            }
        }
        // After a swipe-delete on the trip-filtered list, refresh the Timeline
        // so the trip's note count updates too.
        viewModel.onNoteDeleted = { [weak self] _ in
            self?.timelineViewModel?.refresh()
        }
        let viewController = NotesListViewController(viewModel: viewModel)
        viewController.hidesBottomBarWhenPushed = true
        // Force viewDidLoad to run before the push animation starts so the
        // tableView/title/etc. are wired in by the time UIKit takes its
        // navbar snapshot — otherwise the title flickers in mid-transition.
        viewController.loadViewIfNeeded()
        navigationController.pushViewController(viewController, animated: true)
        tripNotesViewModel = viewModel
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

extension TimelineCoordinator: NoteModuleOutput {
    func noteModuleDidSave(note: Note) {
        // The save may have changed countryCode / dates → refresh both lists.
        tripNotesViewModel?.viewWillAppear()
        timelineViewModel?.refresh()
    }

    func noteModuleDidDelete(noteId: String) {
        tripNotesViewModel?.viewWillAppear()
        timelineViewModel?.refresh()
    }
}
