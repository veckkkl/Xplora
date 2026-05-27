//
//  OnboardingViewModel.swift
//  Xplora
//

enum CountrySelection {
    case none
    case country(code: String, name: String)
    case worldCitizen

    var isSelected: Bool {
        if case .none = self { return false }
        return true
    }
}

@MainActor
protocol OnboardingViewModelInput: AnyObject {
    func viewDidLoad()
    func didChangeName(_ name: String)
    func didSelectPlace(_ place: CatalogPlace)
    func didToggleWorldCitizen(_ enabled: Bool)
    func didTapContinue()
}

@MainActor
protocol OnboardingViewModelOutput: AnyObject {
    var onContinueEnabled: ((Bool) -> Void)? { get set }
    var onNameError: ((String?) -> Void)? { get set }
    var onCountrySelectionChanged: ((CountrySelection) -> Void)? { get set }
    var onCountryError: ((String?) -> Void)? { get set }
    var onCompleted: (() -> Void)? { get set }
}

@MainActor
final class OnboardingViewModel: OnboardingViewModelInput, OnboardingViewModelOutput {
    var onContinueEnabled: ((Bool) -> Void)?
    var onNameError: ((String?) -> Void)?
    var onCountrySelectionChanged: ((CountrySelection) -> Void)?
    var onCountryError: ((String?) -> Void)?
    var onCompleted: (() -> Void)?

    private let completeOnboarding: CompleteOnboardingUseCase
    private let validator = ProfileDetailsViewModel()
    private var currentName = ""
    private var nameValid = false
    private var countrySelection: CountrySelection = .none

    init(completeOnboarding: CompleteOnboardingUseCase) {
        self.completeOnboarding = completeOnboarding
    }

    func viewDidLoad() {
        onContinueEnabled?(false)
    }

    func didChangeName(_ name: String) {
        currentName = name
        switch validator.validateName(name) {
        case .valid:
            nameValid = true
            onNameError?(nil)
        case .tooLong(let max):
            nameValid = false
            onNameError?(L10n.Profile.Details.Validation.tooLongName(max))
        case .empty:
            nameValid = false
            onNameError?(nil)
        case .invalidCharacters:
            nameValid = false
            onNameError?(L10n.Profile.Details.Validation.invalidCharacters)
        }
        updateContinueState()
    }

    /// Onboarding stores only the catalog code; `name` keeps the user-facing
    /// label (localized) so the UI label and `CountrySelection.country(.name)`
    /// payload remain consistent. Status is intentionally not persisted —
    /// Onboarding treats every catalog entry equally.
    func didSelectPlace(_ place: CatalogPlace) {
        countrySelection = .country(code: place.code, name: place.localizedName)
        onCountrySelectionChanged?(countrySelection)
        onCountryError?(nil)
        updateContinueState()
    }

    func didToggleWorldCitizen(_ enabled: Bool) {
        countrySelection = enabled ? .worldCitizen : .none
        onCountrySelectionChanged?(countrySelection)
        onCountryError?(nil)
        updateContinueState()
    }

    func didTapContinue() {
        switch validator.validateName(currentName) {
        case .valid(let trimmed):
            guard countrySelection.isSelected else {
                onCountryError?(L10n.Onboarding.Error.countryRequired)
                return
            }
            let code: String?
            let isWorldCitizen: Bool
            switch countrySelection {
            case .country(let c, _): (code, isWorldCitizen) = (c, false)
            case .worldCitizen:      (code, isWorldCitizen) = (nil, true)
            case .none:              return
            }
            completeOnboarding.execute(name: trimmed, residenceCountryCode: code, isWorldCitizen: isWorldCitizen)
            onCompleted?()
        case .empty:
            onNameError?(L10n.Profile.Details.Validation.emptyName)
        case .tooLong(let max):
            onNameError?(L10n.Profile.Details.Validation.tooLongName(max))
        case .invalidCharacters:
            onNameError?(L10n.Profile.Details.Validation.invalidCharacters)
        }
    }

    private func updateContinueState() {
        onContinueEnabled?(nameValid && countrySelection.isSelected)
    }
}
