//
//  MapCoordinator.swift
//  Xplora


import UIKit

@MainActor
final class MapCoordinator {
    private let navigationController: UINavigationController
    private let locator: ServiceLocator
    private var mapViewModel: MapViewModel?
    private var noteRouter: NoteRouter?

    init(navigationController: UINavigationController, locator: ServiceLocator = .shared) {
        self.navigationController = navigationController
        self.locator = locator
    }

    func start() {
        let markersUseCase: GetCountryVisitMarkersUseCase = locator.resolve(GetCountryVisitMarkersUseCase.self)
        let getNoteUseCase: GetNoteUseCase = locator.resolve(GetNoteUseCase.self)
        let fogOverlayProvider: FogOverlayProviding = locator.resolve(FogOverlayProviding.self)
        let locationService: LocationService = locator.resolve(LocationService.self)
        let viewModel = MapViewModel(
            getCountryVisitMarkersUseCase: markersUseCase,
            getNoteUseCase: getNoteUseCase,
            fogOverlayProvider: fogOverlayProvider,
            locationService: locationService
        )
        let viewController = MapViewController(viewModel: viewModel)
        viewModel.onRoute = { [weak self] route in
            self?.handle(route)
        }
        navigationController.viewControllers = [viewController]
        mapViewModel = viewModel

        let saveNoteUseCase: SaveNoteUseCase = locator.resolve(SaveNoteUseCase.self)
        let deleteNoteUseCase: DeleteNoteUseCase = locator.resolve(DeleteNoteUseCase.self)
        let noteBuilder = NoteModuleBuilder(
            getNoteUseCase: getNoteUseCase,
            saveNoteUseCase: saveNoteUseCase,
            deleteNoteUseCase: deleteNoteUseCase
        )
        noteRouter = NoteRouterImpl(navigationController: navigationController, builder: noteBuilder)
    }

    private func handle(_ route: MapRoute) {
        switch route {
        case .addNote:
            showAddNote()
        case .showCountryFirstNote(_, let noteId, let coordinate):
            showCountryFirstNote(noteId: noteId, coordinate: coordinate)
        }
    }

    private func showAddNote() {
        let locationService: LocationService = locator.resolve(LocationService.self)
        Task { [weak self] in
            let coordinate: LocationCoordinate?
            do {
                coordinate = try await locationService.requestCurrentLocation()
            } catch {
                coordinate = nil
            }
            await MainActor.run {
                self?.noteRouter?.showNote(noteId: nil, coordinate: coordinate, output: self)
            }
        }
    }

    private func showCountryFirstNote(noteId: String?, coordinate: LocationCoordinate) {
        noteRouter?.showNote(noteId: noteId, coordinate: coordinate, output: self)
    }
}

extension MapCoordinator: NoteModuleOutput {
    func noteModuleDidSave(note: Note) {
        mapViewModel?.refreshMarkers()
    }

    func noteModuleDidDelete(noteId: String) {
        mapViewModel?.refreshMarkers()
    }
}
