//
//  ProfileInitialsTests.swift
//  XploraTests
//

import Testing
@testable import Xplora

struct ProfileInitialsTests {

    @Test func singleWord_isFirstLetterUppercased() {
        #expect(ProfileUserSettings.initials(from: "anna") == "A")
    }

    @Test func twoWords_areBothFirstLetters() {
        #expect(ProfileUserSettings.initials(from: "Anna Maria") == "AM")
    }

    @Test func moreThanTwoWords_usesFirstTwo() {
        #expect(ProfileUserSettings.initials(from: "Anna Maria Lopez") == "AM")
    }

    @Test func emptyName_isNil() {
        #expect(ProfileUserSettings.initials(from: "") == nil)
    }

    @Test func whitespaceOnlyName_isNil() {
        #expect(ProfileUserSettings.initials(from: "  \n\t ") == nil)
    }

    @Test func surroundingWhitespace_isIgnored() {
        #expect(ProfileUserSettings.initials(from: "  John   Smith  ") == "JS")
    }

    @Test func cyrillicName_usesCyrillicLetters() {
        #expect(ProfileUserSettings.initials(from: "иван петров") == "ИП")
    }

    @Test func accentedLetters_arePreserved() {
        #expect(ProfileUserSettings.initials(from: "émile zola") == "ÉZ")
    }

    @Test func leadingPunctuation_isSkipped() {
        #expect(ProfileUserSettings.initials(from: "'Anna .Maria") == "AM")
    }

    @Test func noLetters_isNil() {
        #expect(ProfileUserSettings.initials(from: "- . '") == nil)
    }
}
