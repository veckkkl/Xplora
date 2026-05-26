//
//  OnboardingViewModelTests.swift
//  XploraTests
//

import Testing
@testable import Xplora

@MainActor
struct OnboardingViewModelTests {

    private func makeSUT() -> (sut: OnboardingViewModel, useCase: MockCompleteOnboardingUseCase) {
        let useCase = MockCompleteOnboardingUseCase()
        return (OnboardingViewModel(completeOnboarding: useCase), useCase)
    }

    // MARK: - Initial state

    @Test func viewDidLoad_continueIsDisabled() {
        let (sut, _) = makeSUT()
        var received: Bool?
        sut.onContinueEnabled = { received = $0 }
        sut.viewDidLoad()
        #expect(received == false)
    }

    // MARK: - Name validation

    @Test func didChangeName_validName_enablesButtonWhenCountryAlsoSelected() {
        let (sut, _) = makeSUT()
        sut.didSelectCountry(CountryOption(code: "US", name: "United States"))
        var received: Bool?
        sut.onContinueEnabled = { received = $0 }
        sut.didChangeName("Alice")
        #expect(received == true)
    }

    @Test func didChangeName_emptyName_keepsContinueDisabled() {
        let (sut, _) = makeSUT()
        sut.didSelectCountry(CountryOption(code: "US", name: "United States"))
        var received: Bool?
        sut.onContinueEnabled = { received = $0 }
        sut.didChangeName("")
        #expect(received == false)
    }

    @Test func didChangeName_invalidCharacters_keepsContinueDisabled() {
        let (sut, _) = makeSUT()
        sut.didSelectCountry(CountryOption(code: "US", name: "United States"))
        var received: Bool?
        sut.onContinueEnabled = { received = $0 }
        sut.didChangeName("Alice123")
        #expect(received == false)
    }

    @Test func didChangeName_validName_noNameError() {
        let (sut, _) = makeSUT()
        var error: String??
        sut.onNameError = { error = $0 }
        sut.didChangeName("Alice")
        #expect(error == .some(nil))
    }

    @Test func didChangeName_invalidCharacters_firesNameError() {
        let (sut, _) = makeSUT()
        var error: String??
        sut.onNameError = { error = $0 }
        sut.didChangeName("Alice@1")
        #expect(error != nil)
        #expect(error! != nil)
    }

    // MARK: - Country selection

    @Test func didSelectCountry_updatesSelection() {
        let (sut, _) = makeSUT()
        var selection: CountrySelection?
        sut.onCountrySelectionChanged = { selection = $0 }
        sut.didSelectCountry(CountryOption(code: "FR", name: "France"))
        if case .country(let code, _) = selection {
            #expect(code == "FR")
        } else {
            Issue.record("Expected .country, got \(String(describing: selection))")
        }
    }

    @Test func didSelectCountry_clearsCountryError() {
        let (sut, _) = makeSUT()
        var error: String??
        sut.onCountryError = { error = $0 }
        sut.didSelectCountry(CountryOption(code: "FR", name: "France"))
        #expect(error == .some(nil))
    }

    // MARK: - World citizen toggle

    @Test func didToggleWorldCitizen_true_setsWorldCitizenSelection() {
        let (sut, _) = makeSUT()
        var selection: CountrySelection?
        sut.onCountrySelectionChanged = { selection = $0 }
        sut.didToggleWorldCitizen(true)
        if case .worldCitizen = selection { } else {
            Issue.record("Expected .worldCitizen, got \(String(describing: selection))")
        }
    }

    @Test func didToggleWorldCitizen_false_clearsSelection() {
        let (sut, _) = makeSUT()
        sut.didToggleWorldCitizen(true)
        var selection: CountrySelection?
        sut.onCountrySelectionChanged = { selection = $0 }
        sut.didToggleWorldCitizen(false)
        guard let received = selection else {
            Issue.record("Selection callback was not called")
            return
        }
        if case .none = received { } else {
            Issue.record("Expected .none, got \(received)")
        }
    }

    @Test func selectingCountryAfterWorldCitizen_overridesSelection() {
        let (sut, _) = makeSUT()
        sut.didToggleWorldCitizen(true)
        var selection: CountrySelection?
        sut.onCountrySelectionChanged = { selection = $0 }
        sut.didSelectCountry(CountryOption(code: "DE", name: "Germany"))
        if case .country(let code, _) = selection {
            #expect(code == "DE")
        } else {
            Issue.record("Expected .country, got \(String(describing: selection))")
        }
    }

    // MARK: - didTapContinue

    @Test func didTapContinue_validNameAndCountry_callsUseCaseOnce() {
        let (sut, useCase) = makeSUT()
        sut.didChangeName("Alice")
        sut.didSelectCountry(CountryOption(code: "US", name: "United States"))
        sut.didTapContinue()
        #expect(useCase.callCount == 1)
    }

    @Test func didTapContinue_validNameAndCountry_passesCorrectParams() {
        let (sut, useCase) = makeSUT()
        sut.didChangeName("Alice")
        sut.didSelectCountry(CountryOption(code: "US", name: "United States"))
        sut.didTapContinue()
        #expect(useCase.lastName == "Alice")
        #expect(useCase.lastCode == "US")
        #expect(useCase.lastIsWorldCitizen == false)
    }

    @Test func didTapContinue_validNameAndWorldCitizen_passesCorrectParams() {
        let (sut, useCase) = makeSUT()
        sut.didChangeName("Bob")
        sut.didToggleWorldCitizen(true)
        sut.didTapContinue()
        #expect(useCase.lastCode == nil)
        #expect(useCase.lastIsWorldCitizen == true)
    }

    @Test func didTapContinue_validNameAndWorldCitizen_firesCompleted() {
        let (sut, _) = makeSUT()
        var completed = false
        sut.onCompleted = { completed = true }
        sut.didChangeName("Bob")
        sut.didToggleWorldCitizen(true)
        sut.didTapContinue()
        #expect(completed == true)
    }

    @Test func didTapContinue_emptyName_doesNotCallUseCase() {
        let (sut, useCase) = makeSUT()
        sut.didSelectCountry(CountryOption(code: "US", name: "United States"))
        sut.didTapContinue()
        #expect(useCase.callCount == 0)
    }

    @Test func didTapContinue_emptyName_firesNameError() {
        let (sut, _) = makeSUT()
        sut.didSelectCountry(CountryOption(code: "US", name: "United States"))
        var error: String??
        sut.onNameError = { error = $0 }
        sut.didTapContinue()
        #expect(error != nil)
        #expect(error! != nil)
    }

    @Test func didTapContinue_validNameNoCountry_doesNotCallUseCase() {
        let (sut, useCase) = makeSUT()
        sut.didChangeName("Alice")
        sut.didTapContinue()
        #expect(useCase.callCount == 0)
    }

    @Test func didTapContinue_validNameNoCountry_firesCountryError() {
        let (sut, _) = makeSUT()
        sut.didChangeName("Alice")
        var error: String??
        sut.onCountryError = { error = $0 }
        sut.didTapContinue()
        #expect(error != nil)
        #expect(error! != nil)
    }

    @Test func didTapContinue_trimmedNameIsPassed() {
        let (sut, useCase) = makeSUT()
        sut.didChangeName("  Alice  ")
        sut.didSelectCountry(CountryOption(code: "US", name: "United States"))
        sut.didTapContinue()
        #expect(useCase.lastName == "Alice")
    }
}
