//
//  ProfileDetailsViewModel.swift
//  Xplora
//

import Foundation

enum ProfileNameValidationResult: Equatable {
    case valid(String)
    case empty
    case tooLong(maxLength: Int)
    case invalidCharacters
}

final class ProfileDetailsViewModel {
    func validateName(_ name: String) -> ProfileNameValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .empty
        }

        guard trimmed.count <= ProfileUserSettings.maxNameLength else {
            return .tooLong(maxLength: ProfileUserSettings.maxNameLength)
        }

        guard isAllowedNameCharacters(trimmed) else {
            return .invalidCharacters
        }

        return .valid(trimmed)
    }

    private func isAllowedNameCharacters(_ name: String) -> Bool {
        for scalar in name.unicodeScalars {
            if CharacterSet.letters.contains(scalar) { continue }
            if scalar == " " || scalar == "-" || scalar == "'" || scalar == "." { continue }
            return false
        }
        return true
    }
}
