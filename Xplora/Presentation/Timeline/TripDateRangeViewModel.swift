//
//  TripDateRangeViewModel.swift
//  Xplora
//

import Foundation

@MainActor
protocol TripDateRangeModuleOutput: AnyObject {
    func tripDateRangeDidSave(tripId: UUID)
    func tripDateRangeDidCancel()
}

enum TripDateRangeMode {
    case create(country: Country)
    case edit(tripId: UUID, country: Country, startDate: Date, endDate: Date)
}

struct TripDateRangeViewState: Equatable {
    let title: String
    let countryDisplay: String
    let startDate: Date
    let endDate: Date
    let saveEnabled: Bool
    let errorMessage: String?
}

@MainActor
protocol TripDateRangeViewModelInput: AnyObject {
    func viewDidLoad()
    func didChangeStartDate(_ date: Date)
    func didChangeEndDate(_ date: Date)
    func didTapSave()
    func didTapCancel()
}

@MainActor
protocol TripDateRangeViewModelOutput: AnyObject {
    var onStateChange: ((TripDateRangeViewState) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
}

@MainActor
final class TripDateRangeViewModel: TripDateRangeViewModelInput, TripDateRangeViewModelOutput {
    var onStateChange: ((TripDateRangeViewState) -> Void)?
    var onError: ((String) -> Void)?

    weak var output: TripDateRangeModuleOutput?

    private let mode: TripDateRangeMode
    private let country: Country
    private var startDate: Date
    private var endDate: Date

    private let createTrip: CreateTripUseCase
    private let updateTripDates: UpdateTripDatesUseCase
    private let validateDates: ValidateTripDateRangeUseCase

    init(
        mode: TripDateRangeMode,
        createTrip: CreateTripUseCase,
        updateTripDates: UpdateTripDatesUseCase,
        validateDates: ValidateTripDateRangeUseCase
    ) {
        self.mode = mode
        self.createTrip = createTrip
        self.updateTripDates = updateTripDates
        self.validateDates = validateDates

        switch mode {
        case .create(let country):
            self.country = country
            let today = Calendar.autoupdatingCurrent.startOfDay(for: Date())
            self.startDate = today
            self.endDate = today
        case let .edit(_, country, startDate, endDate):
            self.country = country
            self.startDate = startDate
            self.endDate = endDate
        }
    }

    func viewDidLoad() {
        publish()
    }

    func didChangeStartDate(_ date: Date) {
        startDate = date
        if endDate < startDate {
            endDate = startDate
        }
        publish()
    }

    func didChangeEndDate(_ date: Date) {
        endDate = date
        publish()
    }

    func didTapCancel() {
        output?.tripDateRangeDidCancel()
    }

    func didTapSave() {
        switch validateDates.execute(startDate: startDate, endDate: endDate) {
        case .success:
            performSave()
        case .failure:
            publish()
        }
    }

    private func performSave() {
        switch mode {
        case .create(let country):
            performCreate(country: country)
        case .edit(let tripId, _, _, _):
            performUpdate(tripId: tripId)
        }
    }

    private func performCreate(country: Country) {
        let start = startDate
        let end = endDate
        Task {
            do {
                let trip = try await createTrip.execute(country: country, startDate: start, endDate: end)
                output?.tripDateRangeDidSave(tripId: trip.id)
            } catch {
                onError?(L10n.Timeline.DateRange.Error.save)
            }
        }
    }

    private func performUpdate(tripId: UUID) {
        let start = startDate
        let end = endDate
        Task {
            do {
                _ = try await updateTripDates.execute(tripId: tripId, startDate: start, endDate: end)
                output?.tripDateRangeDidSave(tripId: tripId)
            } catch {
                onError?(L10n.Timeline.DateRange.Error.save)
            }
        }
    }

    private func publish() {
        let validation = validateDates.execute(startDate: startDate, endDate: endDate)
        let saveEnabled: Bool
        let errorMessage: String?
        switch validation {
        case .success:
            saveEnabled = true
            errorMessage = nil
        case .failure(let error):
            saveEnabled = false
            errorMessage = userFriendlyMessage(for: error)
        }

        let title: String
        switch mode {
        case .create: title = L10n.Timeline.DateRange.Title.create
        case .edit: title = L10n.Timeline.DateRange.Title.edit
        }

        let flag = flagEmoji(for: country.code)
        let countryDisplay = "\(flag) \(country.name)".trimmingCharacters(in: .whitespaces)

        onStateChange?(
            TripDateRangeViewState(
                title: title,
                countryDisplay: countryDisplay,
                startDate: startDate,
                endDate: endDate,
                saveEnabled: saveEnabled,
                errorMessage: errorMessage
            )
        )
    }

    private func userFriendlyMessage(for error: TripDateValidationError) -> String {
        switch error {
        case .startDateAfterEndDate:
            return L10n.Timeline.DateRange.Error.endBeforeStart
        case .startDateInFuture:
            return L10n.Timeline.DateRange.Error.startInFuture
        }
    }

    private func flagEmoji(for countryCode: String) -> String {
        countryCode
            .uppercased()
            .unicodeScalars
            .compactMap { Unicode.Scalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }
}
