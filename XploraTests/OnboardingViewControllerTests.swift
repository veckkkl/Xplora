//
//  OnboardingViewControllerTests.swift
//  XploraTests
//
//  The view controller keeps its subviews and view model private, so these
//  tests drive the real view model and observe the wired-up continue button
//  through the view hierarchy — verifying the VC<->VM binding end to end
//  without exposing internals.
//

import UIKit
import Testing
@testable import Xplora

@MainActor
struct OnboardingViewControllerTests {

    private func makeSUT() -> (sut: OnboardingViewController, viewModel: OnboardingViewModel) {
        let viewModel = OnboardingViewModel(completeOnboarding: MockCompleteOnboardingUseCase())
        let sut = OnboardingViewController(
            viewModel: viewModel,
            getCatalogPlaces: MockGetCatalogPlacesUseCase()
        )
        return (sut, viewModel)
    }

    private func continueButton(in view: UIView) -> UIButton? {
        view.allSubviewsRecursive.compactMap { $0 as? UIButton }.first
    }

    @Test func viewDidLoad_disablesContinueButton() {
        let (sut, _) = makeSUT()
        sut.loadViewIfNeeded()
        #expect(continueButton(in: sut.view)?.isEnabled == false)
    }

    @Test func selectingNameAndCountry_enablesContinueButton() {
        let (sut, viewModel) = makeSUT()
        sut.loadViewIfNeeded()
        viewModel.didSelectPlace(CatalogPlace(code: "US", status: .un))
        viewModel.didChangeName("Alice")
        #expect(continueButton(in: sut.view)?.isEnabled == true)
    }

    @Test func clearingNameAfterValid_disablesContinueButton() {
        let (sut, viewModel) = makeSUT()
        sut.loadViewIfNeeded()
        viewModel.didSelectPlace(CatalogPlace(code: "US", status: .un))
        viewModel.didChangeName("Alice")
        viewModel.didChangeName("")
        #expect(continueButton(in: sut.view)?.isEnabled == false)
    }
}

private extension UIView {
    var allSubviewsRecursive: [UIView] {
        subviews + subviews.flatMap { $0.allSubviewsRecursive }
    }
}
