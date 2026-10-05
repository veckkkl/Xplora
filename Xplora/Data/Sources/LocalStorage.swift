//
//  LocalStorage.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//
import Foundation
import os

final class LocalStorage: LocalStorageProtocol {

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(value)
        } catch {
            Logger.storage.error(
                "LocalStorage encode failed key=\(key, privacy: .public) error=\(Self.describe(error), privacy: .public)"
            )
            throw LocalStorageError.encodingFailed(key: key, underlying: error)
        }
        userDefaults.set(data, forKey: key)
    }

    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            if userDefaults.object(forKey: key) != nil {
                // Something is stored under the key, but it isn't Data.
                Logger.storage.error(
                    "LocalStorage read failed key=\(key, privacy: .public) reason=unexpectedValueType"
                )
                throw LocalStorageError.decodingFailed(key: key, underlying: CocoaError(.coderReadCorrupt))
            }
            return nil
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            Logger.storage.error(
                "LocalStorage decode failed key=\(key, privacy: .public) type=\(String(describing: T.self), privacy: .public) bytes=\(data.count, privacy: .public) error=\(Self.describe(error), privacy: .public)"
            )
            throw LocalStorageError.decodingFailed(key: key, underlying: error)
        }
    }

    func removeValue(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }

    /// Technical summary of a coding error without payload values.
    private static func describe(_ error: Error) -> String {
        func path(_ codingPath: [CodingKey]) -> String {
            codingPath.map { $0.intValue.map(String.init) ?? $0.stringValue }.joined(separator: ".")
        }
        switch error {
        case DecodingError.typeMismatch(_, let context):
            return "typeMismatch path=\(path(context.codingPath))"
        case DecodingError.valueNotFound(_, let context):
            return "valueNotFound path=\(path(context.codingPath))"
        case DecodingError.keyNotFound(let key, let context):
            return "keyNotFound key=\(key.stringValue) path=\(path(context.codingPath))"
        case DecodingError.dataCorrupted(let context):
            return "dataCorrupted path=\(path(context.codingPath))"
        case EncodingError.invalidValue(_, let context):
            return "invalidValue path=\(path(context.codingPath))"
        default:
            return String(describing: type(of: error))
        }
    }
}
