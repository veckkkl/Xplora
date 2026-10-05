//
//  DeleteAllUserDataUseCaseTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

// MARK: - Environment

/// Real repositories over isolated storage: MockLocalStorage, an in-memory
/// Core Data stack, temp directories and a throwaway UserDefaults suite.
private final class DeleteAllEnvironment {
    let storage = MockLocalStorage()
    let coreDataStack: CoreDataStack
    let rootURL: URL
    let photosBaseURL: URL
    let avatarDirectoryURL: URL
    let defaultsSuiteName = "DeleteAllUserDataUseCaseTests-\(UUID().uuidString)"
    let defaults: UserDefaults

    let notesRepo: NotesRepoImpl
    let photoStore: FileNotePhotoStore
    let tripsRepo: TripsRepoImpl
    let wishlistRepo: WishlistRepoImpl
    let settingsRepo: SettingsRepoImpl
    let authRepository: AuthRepositoryImpl
    let profileDataStore: LocalProfileDataStore

    private(set) var photoPath = ""

    init(coreDataStack: CoreDataStack = CoreDataStack(inMemory: true)) throws {
        self.coreDataStack = coreDataStack
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("DeleteAllUserData-\(UUID().uuidString)", isDirectory: true)
        photosBaseURL = rootURL.appendingPathComponent("AppSupport", isDirectory: true)
        avatarDirectoryURL = rootURL.appendingPathComponent("ProfileAvatar", isDirectory: true)
        try FileManager.default.createDirectory(at: photosBaseURL, withIntermediateDirectories: true)
        defaults = UserDefaults(suiteName: defaultsSuiteName)!

        notesRepo = NotesRepoImpl(coreDataStack: coreDataStack)
        let base = photosBaseURL
        photoStore = FileNotePhotoStore(baseDirectoryURL: { base })
        tripsRepo = TripsRepoImpl(storage: storage)
        wishlistRepo = WishlistRepoImpl(storage: storage)
        settingsRepo = SettingsRepoImpl(storage: storage)
        authRepository = AuthRepositoryImpl(storage: storage)
        profileDataStore = LocalProfileDataStore(defaults: defaults, avatarDirectoryURL: avatarDirectoryURL)
    }

    deinit {
        try? FileManager.default.removeItem(at: rootURL)
        UserDefaults().removePersistentDomain(forName: defaultsSuiteName)
    }

    func makeSUT(
        tripsRepo: TripsRepo? = nil,
        photoStore: NotePhotoStore? = nil
    ) -> DeleteAllUserDataUseCaseImpl {
        DeleteAllUserDataUseCaseImpl(
            notesRepo: notesRepo,
            photoStore: photoStore ?? self.photoStore,
            tripsRepo: tripsRepo ?? self.tripsRepo,
            wishlistRepo: wishlistRepo,
            settingsRepo: settingsRepo,
            profileDataStore: profileDataStore,
            authRepository: authRepository
        )
    }

    /// One of everything: a note with a photo file, a trip, a wishlist entry,
    /// settings, the local user, profile values, avatar file and theme.
    func seed() async throws {
        let noteId = UUID().uuidString
        photoPath = try await photoStore.savePhoto(Data([0xFF, 0xD8, 0xFF]), noteId: noteId)
        let now = Date()
        _ = try await notesRepo.save(note: Note(
            id: noteId,
            title: "Title",
            text: "Text",
            createdAt: now,
            updatedAt: now,
            tripStartDate: nil,
            tripEndDate: nil,
            isBookmarked: false,
            location: nil,
            photos: [NotePhoto(id: UUID().uuidString, localPath: photoPath, createdAt: now, orderIndex: 0)],
            headerTitle: nil
        ))

        try await tripsRepo.save(trip: Trip(
            id: UUID(),
            placeCode: "FR",
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 86_400),
            notesCount: 0,
            visitedPlaces: []
        ))
        try await wishlistRepo.add(WishlistCountry(
            id: UUID(),
            code: "IT",
            flag: "",
            name: "IT",
            cityKey: nil,
            note: nil,
            isCompleted: false,
            addedAt: Date(timeIntervalSince1970: 0)
        ))
        try await settingsRepo.saveSettings(UserSettings(preferredUnits: .miles, showFog: false))
        try authRepository.completeOnboarding(name: "Alice", residenceCountryCode: "FR", isWorldCitizen: false)

        defaults.set("Alice", forKey: "profile.user.name")
        defaults.set(false, forKey: "profile.user.is_status_visible")
        defaults.set("avatar.jpg", forKey: "profile.user.avatar_file_name")
        defaults.set(AppTheme.dark.rawValue, forKey: AppThemeManager.storageKey)
        try FileManager.default.createDirectory(at: avatarDirectoryURL, withIntermediateDirectories: true)
        try Data([1, 2, 3]).write(to: avatarDirectoryURL.appendingPathComponent("avatar.jpg"))
    }

    var photoFileURL: URL { photosBaseURL.appendingPathComponent(photoPath) }
    var notesPhotoDirectoryURL: URL { photosBaseURL.appendingPathComponent("Notes", isDirectory: true) }
}

// MARK: - Failing doubles

private struct InjectedFailure: Error {}

private final class FailingTripsRepo: TripsRepo {
    func getAllTrips() async throws -> [Trip] { throw InjectedFailure() }
    func getTrip(id: UUID) async throws -> Trip { throw InjectedFailure() }
    func save(trip: Trip) async throws { throw InjectedFailure() }
    func update(trip: Trip) async throws { throw InjectedFailure() }
    func delete(tripId: UUID) async throws { throw InjectedFailure() }
    func deleteAll() async throws { throw InjectedFailure() }
}

private final class FailingDeletePhotoStore: NotePhotoStore, @unchecked Sendable {
    func savePhoto(_ jpegData: Data, noteId: String) async throws -> String { throw InjectedFailure() }
    func loadPhotoData(at localPath: String) async throws -> Data { throw InjectedFailure() }
    func contentHash(ofPhotoAt localPath: String) async throws -> String { throw InjectedFailure() }
    func deletePhoto(at localPath: String) async throws { throw InjectedFailure() }
    func deleteAllPhotos(noteId: String) async throws { throw InjectedFailure() }
    func deleteAllNotePhotos() async throws { throw InjectedFailure() }
}

// MARK: - Tests

struct DeleteAllUserDataUseCaseTests {

    @Test func execute_clearsEveryStore() async throws {
        let env = try DeleteAllEnvironment()
        try await env.seed()

        try await env.makeSUT().execute()

        #expect(try await env.notesRepo.fetchAllNotes().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: env.notesPhotoDirectoryURL.path))
        #expect(try await env.tripsRepo.getAllTrips().isEmpty)
        #expect(try await env.wishlistRepo.getAll().isEmpty)
        #expect(try env.authRepository.getCurrentUser() == nil)
        #expect(!FileManager.default.fileExists(atPath: env.avatarDirectoryURL.path))
        // Nothing user-owned is left in local storage.
        #expect(env.storage.store.isEmpty)
    }

    @Test func execute_deletesNotes() async throws {
        let env = try DeleteAllEnvironment()
        try await env.seed()
        #expect(try await env.notesRepo.fetchAllNotes().count == 1)

        try await env.makeSUT().execute()

        #expect(try await env.notesRepo.fetchAllNotes().isEmpty)
    }

    @Test func execute_deletesPhotoFilesIncludingUnreferencedOnes() async throws {
        let env = try DeleteAllEnvironment()
        try await env.seed()
        let orphan = try await env.photoStore.savePhoto(Data([0x01]), noteId: "orphan-note")
        #expect(FileManager.default.fileExists(atPath: env.photoFileURL.path))

        try await env.makeSUT().execute()

        #expect(!FileManager.default.fileExists(atPath: env.photoFileURL.path))
        #expect(!FileManager.default.fileExists(atPath: env.photosBaseURL.appendingPathComponent(orphan).path))
    }

    @Test func execute_deletesTrips() async throws {
        let env = try DeleteAllEnvironment()
        try await env.seed()

        try await env.makeSUT().execute()

        #expect(try await env.tripsRepo.getAllTrips().isEmpty)
    }

    @Test func execute_deletesWishlist() async throws {
        let env = try DeleteAllEnvironment()
        try await env.seed()

        try await env.makeSUT().execute()

        #expect(try await env.wishlistRepo.getAll().isEmpty)
    }

    @Test func execute_deletesAuthUser() async throws {
        let env = try DeleteAllEnvironment()
        try await env.seed()

        try await env.makeSUT().execute()

        #expect(try env.authRepository.getCurrentUser() == nil)
    }

    @Test func execute_clearsProfileAvatarAndPreferences() async throws {
        let env = try DeleteAllEnvironment()
        try await env.seed()

        try await env.makeSUT().execute()

        #expect(env.defaults.object(forKey: "profile.user.name") == nil)
        #expect(env.defaults.object(forKey: "profile.user.is_status_visible") == nil)
        #expect(env.defaults.object(forKey: "profile.user.avatar_file_name") == nil)
        #expect(!FileManager.default.fileExists(atPath: env.avatarDirectoryURL.path))
        #expect(AppThemeManager(defaults: env.defaults).currentTheme == .system)
        #expect(try await env.settingsRepo.loadSettings().preferredUnits == UserSettings.default.preferredUnits)
    }

    @Test func execute_keepsCatalogCache() async throws {
        let env = try DeleteAllEnvironment()
        try await env.seed()
        try env.storage.saveCachedCatalogCodes(["FR", "IT"])

        try await env.makeSUT().execute()

        #expect(try env.storage.loadCachedCatalogCodes() == ["FR", "IT"])
    }

    @Test func execute_whenNothingStored_succeeds() async throws {
        let env = try DeleteAllEnvironment()
        try await env.makeSUT().execute()
    }

    // MARK: - Partial failure

    @Test func execute_whenOneStepFails_throwsAndKeepsUser() async throws {
        let env = try DeleteAllEnvironment()
        try await env.seed()

        await #expect(throws: DeleteAllUserDataError.partialFailure(failed: [.trips])) {
            try await env.makeSUT(tripsRepo: FailingTripsRepo()).execute()
        }

        // The user stays signed in so the app doesn't restart onboarding over leftover data…
        #expect(try env.authRepository.getCurrentUser() != nil)
        // …while the remaining categories were still cleared.
        #expect(try await env.wishlistRepo.getAll().isEmpty)
        #expect(try await env.notesRepo.fetchAllNotes().isEmpty)
    }

    @Test func execute_whenPhotoDeletionFails_keepsNoteRecords() async throws {
        let env = try DeleteAllEnvironment()
        try await env.seed()

        await #expect(throws: DeleteAllUserDataError.partialFailure(failed: [.notes])) {
            try await env.makeSUT(photoStore: FailingDeletePhotoStore()).execute()
        }

        // Records still point at the files, so a retry can find them.
        #expect(try await env.notesRepo.fetchAllNotes().count == 1)
        #expect(try env.authRepository.getCurrentUser() != nil)
    }

    @Test func execute_whenNotesStoreUnavailable_failsAndLeavesPhotoFiles() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DeleteAllBrokenStore-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("Broken.sqlite")
        try Data(repeating: 0x42, count: 4096).write(to: storeURL)

        let env = try DeleteAllEnvironment(coreDataStack: CoreDataStack(storeURL: storeURL))
        let photoPath = try await env.photoStore.savePhoto(Data([0x01]), noteId: "note")

        await #expect(throws: DeleteAllUserDataError.partialFailure(failed: [.notes])) {
            try await env.makeSUT().execute()
        }

        // Photos of notes that can't be read are not touched.
        #expect(FileManager.default.fileExists(atPath: env.photosBaseURL.appendingPathComponent(photoPath).path))
    }
}

// MARK: - UI reaction

@MainActor
struct DeleteAllDataPresentationTests {

    private func makeProfileViewModel(deleteAll: MockDeleteAllUserDataUseCase) -> ProfileViewModel {
        ProfileViewModel(
            getCurrentUser: MockGetCurrentUserUseCase(),
            updateCurrentUser: MockUpdateCurrentUserUseCase(),
            getStatistics: MockGetStatisticsUseCase(),
            getTrips: MockGetTripsUseCase(),
            deleteAllUserData: deleteAll,
            themeManager: MockAppThemeManager()
        )
    }

    @Test func profile_deleteSucceeds_routesToRestart() async {
        let deleteAll = MockDeleteAllUserDataUseCase()
        let sut = makeProfileViewModel(deleteAll: deleteAll)
        var routes: [ProfileRoute] = []
        var failure: String?
        sut.onRoute = { routes.append($0) }
        sut.onDeleteAllDataFailed = { failure = $0 }

        await sut.deleteAllData()

        #expect(deleteAll.callCount == 1)
        #expect(routes == [.allDataDeleted])
        #expect(failure == nil)
    }

    @Test func profile_partialFailure_showsErrorAndNeverSuccess() async {
        let deleteAll = MockDeleteAllUserDataUseCase()
        deleteAll.stubbedError = DeleteAllUserDataError.partialFailure(failed: [.trips])
        let sut = makeProfileViewModel(deleteAll: deleteAll)
        var routes: [ProfileRoute] = []
        var failure: String?
        var progress: [Bool] = []
        sut.onRoute = { routes.append($0) }
        sut.onDeleteAllDataFailed = { failure = $0 }
        sut.onDeleteAllDataInProgress = { progress.append($0) }

        await sut.deleteAllData()

        #expect(routes.isEmpty)
        #expect(failure == L10n.Profile.Delete.errorMessage)
        #expect(progress == [true, false])
    }
}
