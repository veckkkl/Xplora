//
//  Logger+Storage.swift
//  Xplora
//

import Foundation
import os

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "Xplora"

    /// Local persistence failures (UserDefaults-backed storage, Core Data).
    /// Log only technical context — never user content or raw payloads.
    static let storage = Logger(subsystem: subsystem, category: "Storage")

    /// Note photo import, processing and file operations.
    /// Never log image data, metadata or file paths.
    static let photos = Logger(subsystem: subsystem, category: "Photos")
}
