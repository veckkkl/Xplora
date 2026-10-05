//
//  ProfileDataStore.swift
//  Xplora
//

/// Local profile data and app preferences that live outside `AuthUser`:
/// display name copy, status visibility, avatar file and theme choice.
protocol ProfileDataStore {
    /// Removes all of it. Throws when something could not be removed.
    func deleteAll() throws
}
