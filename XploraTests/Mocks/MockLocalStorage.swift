//
//  MockLocalStorage.swift
//  XploraTests
//

import Foundation
@testable import Xplora

final class MockLocalStorage: LocalStorageProtocol {
    /// Raw stored bytes, exposed so tests can seed corrupted data and
    /// verify that failed operations leave it untouched.
    var store: [String: Data] = [:]
    /// When set, every `save` throws this error and writes nothing.
    var saveError: Error?
    private(set) var saveCallCount = 0

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        saveCallCount += 1
        if let saveError { throw saveError }
        do {
            store[key] = try JSONEncoder().encode(value)
        } catch {
            throw LocalStorageError.encodingFailed(key: key, underlying: error)
        }
    }

    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = store[key] else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw LocalStorageError.decodingFailed(key: key, underlying: error)
        }
    }

    func removeValue(forKey key: String) {
        store.removeValue(forKey: key)
    }
}
