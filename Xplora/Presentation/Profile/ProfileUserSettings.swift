//
//  ProfileUserSettings.swift
//  Xplora
//

import Foundation
import UIKit

enum ProfileUserSettings {
    private enum Keys {
        static let name = "profile.user.name"
        static let isStatusVisible = "profile.user.is_status_visible"
        static let avatarFileName = "profile.user.avatar_file_name"
    }

    static let maxNameLength = 40
    static let defaultName = "valentina balde"

    static var currentName: String {
        let storedName = UserDefaults.standard.string(forKey: Keys.name) ?? defaultName
        let trimmed = storedName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultName : trimmed
    }

    static var currentStatus: ProfileStatus {
        .worldExplorer
    }

    static var currentAvatarFileName: String? {
        UserDefaults.standard.string(forKey: Keys.avatarFileName)
    }

    static var isStatusVisible: Bool {
        if UserDefaults.standard.object(forKey: Keys.isStatusVisible) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: Keys.isStatusVisible)
    }

    static func saveName(_ name: String) {
        UserDefaults.standard.set(name.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Keys.name)
    }

    static func saveStatusVisibility(_ isVisible: Bool) {
        UserDefaults.standard.set(isVisible, forKey: Keys.isStatusVisible)
    }

    @discardableResult
    static func saveAvatarImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }

        let newFileName = "avatar-\(UUID().uuidString).jpg"
        let newFileURL = avatarDirectoryURL.appendingPathComponent(newFileName)

        do {
            try FileManager.default.createDirectory(at: avatarDirectoryURL, withIntermediateDirectories: true)
            try data.write(to: newFileURL, options: .atomic)

            if let oldFileName = currentAvatarFileName, oldFileName != newFileName {
                let oldFileURL = avatarDirectoryURL.appendingPathComponent(oldFileName)
                try? FileManager.default.removeItem(at: oldFileURL)
            }

            UserDefaults.standard.set(newFileName, forKey: Keys.avatarFileName)
            return newFileName
        } catch {
            return nil
        }
    }

    static func loadCurrentAvatarImage() -> UIImage? {
        loadAvatarImage(fileName: currentAvatarFileName)
    }

    static func loadAvatarImage(fileName: String?) -> UIImage? {
        guard let fileName else { return nil }
        let fileURL = avatarDirectoryURL.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    static func initials(from name: String) -> String {
        let components = name
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .prefix(2)

        let letters = components.compactMap { component in
            component.first.map { String($0).uppercased() }
        }

        if letters.isEmpty {
            return "VB"
        }

        return letters.joined()
    }

    private static var avatarDirectoryURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return baseURL.appendingPathComponent("ProfileAvatar", isDirectory: true)
    }
}
