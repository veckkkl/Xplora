//
//  DeleteAllUserDataUseCase.swift
//  Xplora
//

import Foundation
import os

/// Parts of local user data removed by `DeleteAllUserDataUseCase`.
enum UserDataCategory: String, CaseIterable {
    case notes
    case trips
    case wishlist
    case settings
    case profile
}

enum DeleteAllUserDataError: Error, Equatable {
    /// Some categories could not be removed. The local user is kept, so the
    /// app stays signed in and the user can retry.
    case partialFailure(failed: [UserDataCategory])
}

/// Removes every piece of local Xplora user data: notes with their photo
/// files, trips, wishlist, settings, profile data and finally the local user.
/// The bundled catalog, the catalog cache and system language settings are kept.
protocol DeleteAllUserDataUseCase {
    func execute() async throws
}

final class DeleteAllUserDataUseCaseImpl: DeleteAllUserDataUseCase {
    private let notesRepo: NotesRepo
    private let photoStore: NotePhotoStore
    private let tripsRepo: TripsRepo
    private let wishlistRepo: WishlistRepo
    private let settingsRepo: SettingsRepo
    private let profileDataStore: ProfileDataStore
    private let authRepository: AuthRepository

    init(
        notesRepo: NotesRepo,
        photoStore: NotePhotoStore,
        tripsRepo: TripsRepo,
        wishlistRepo: WishlistRepo,
        settingsRepo: SettingsRepo,
        profileDataStore: ProfileDataStore,
        authRepository: AuthRepository
    ) {
        self.notesRepo = notesRepo
        self.photoStore = photoStore
        self.tripsRepo = tripsRepo
        self.wishlistRepo = wishlistRepo
        self.settingsRepo = settingsRepo
        self.profileDataStore = profileDataStore
        self.authRepository = authRepository
    }

    /// Best-effort across categories: every category is attempted even if an
    /// earlier one failed, so a retry has less left to do. Each step is
    /// idempotent. The local user is removed only when everything else
    /// succeeded — otherwise onboarding could start while old data remains.
    func execute() async throws {
        var failed: [UserDataCategory] = []

        for category in UserDataCategory.allCases {
            do {
                try await delete(category)
            } catch {
                failed.append(category)
                let nsError = error as NSError
                Logger.storage.error(
                    "DeleteAllUserData step=\(category.rawValue, privacy: .public) failed domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
                )
            }
        }

        guard failed.isEmpty else {
            throw DeleteAllUserDataError.partialFailure(failed: failed)
        }
        authRepository.logout()
    }

    private func delete(_ category: UserDataCategory) async throws {
        switch category {
        case .notes:
            try await deleteNotesAndPhotos()
        case .trips:
            try await tripsRepo.deleteAll()
        case .wishlist:
            try await wishlistRepo.removeAll()
        case .settings:
            try await settingsRepo.deleteSettings()
        case .profile:
            try profileDataStore.deleteAll()
        }
    }

    /// Sequential with early exit: photo files go first and note records are
    /// deleted only after that succeeded, so a failed run keeps the records
    /// that point at any remaining files (including legacy absolute paths).
    /// If notes can't be read (e.g. the store is unavailable), nothing is touched.
    private func deleteNotesAndPhotos() async throws {
        let notes = try await notesRepo.fetchAllNotes()
        for note in notes {
            for photo in note.photos {
                try await photoStore.deletePhoto(at: photo.localPath)
            }
        }
        try await photoStore.deleteAllNotePhotos()
        try await notesRepo.deleteAll()
    }
}
