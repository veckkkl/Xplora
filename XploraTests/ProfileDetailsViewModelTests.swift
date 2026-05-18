//
//  ProfileDetailsViewModelTests.swift
//  XploraTests
//

import Testing
@testable import Xplora

struct ProfileDetailsViewModelTests {
    private let sut = ProfileDetailsViewModel()

    // MARK: - .empty

    @Test func validateName_emptyString_returnsEmpty() {
        #expect(sut.validateName("") == .empty)
    }

    @Test func validateName_whitespaceOnly_returnsEmpty() {
        #expect(sut.validateName("   ") == .empty)
    }

    @Test func validateName_newlineOnly_returnsEmpty() {
        #expect(sut.validateName("\n") == .empty)
    }

    // MARK: - .tooLong

    @Test func validateName_exactlyMaxLength_returnsValid() {
        let name = String(repeating: "a", count: ProfileUserSettings.maxNameLength)
        #expect(sut.validateName(name) == .valid(name))
    }

    @Test func validateName_exceedsMaxLength_returnsTooLong() {
        let name = String(repeating: "a", count: ProfileUserSettings.maxNameLength + 1)
        #expect(sut.validateName(name) == .tooLong(maxLength: ProfileUserSettings.maxNameLength))
    }

    // MARK: - .invalidCharacters

    @Test func validateName_digit_returnsInvalidCharacters() {
        #expect(sut.validateName("John2") == .invalidCharacters)
    }

    @Test func validateName_atSign_returnsInvalidCharacters() {
        #expect(sut.validateName("John@Doe") == .invalidCharacters)
    }

    @Test func validateName_underscore_returnsInvalidCharacters() {
        #expect(sut.validateName("John_Doe") == .invalidCharacters)
    }

    // MARK: - .valid

    @Test func validateName_latinLetters_returnsValid() {
        #expect(sut.validateName("John") == .valid("John"))
    }

    @Test func validateName_cyrillicLetters_returnsValid() {
        #expect(sut.validateName("Иван") == .valid("Иван"))
    }

    @Test func validateName_hyphen_returnsValid() {
        #expect(sut.validateName("Mary-Jane") == .valid("Mary-Jane"))
    }

    @Test func validateName_apostrophe_returnsValid() {
        #expect(sut.validateName("O'Brien") == .valid("O'Brien"))
    }

    @Test func validateName_dot_returnsValid() {
        #expect(sut.validateName("Jr.") == .valid("Jr."))
    }

    @Test func validateName_space_returnsValid() {
        #expect(sut.validateName("John Doe") == .valid("John Doe"))
    }

    @Test func validateName_leadingTrailingWhitespace_isTrimmed() {
        #expect(sut.validateName("  Anna  ") == .valid("Anna"))
    }

    @Test func validateName_fullName_returnsValid() {
        #expect(sut.validateName("Valentina Balde") == .valid("Valentina Balde"))
    }
}
