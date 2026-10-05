//
//  CoreDataStackTests.swift
//  XploraTests
//

import Foundation
import Testing
@testable import Xplora

struct CoreDataStackTests {

    @Test func inMemoryStore_loads() async throws {
        let stack = CoreDataStack(inMemory: true)
        #expect(stack.isStoreLoaded)
        #expect(stack.loadError == nil)
        let notes = try await NotesRepoImpl(coreDataStack: stack).fetchAllNotes()
        #expect(notes.isEmpty)
    }

    @Test func corruptedStoreFile_isReportedAndLeftUntouched() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoreDataStackTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appendingPathComponent("Broken.sqlite")
        let garbage = Data(repeating: 0x42, count: 4096)
        try garbage.write(to: storeURL)

        let stack = CoreDataStack(storeURL: storeURL)

        #expect(!stack.isStoreLoaded)
        #expect(throws: CoreDataStackError.self) { try stack.loadedViewContext() }
        await #expect(throws: CoreDataStackError.self) {
            try await NotesRepoImpl(coreDataStack: stack).fetchAllNotes()
        }
        #expect(try Data(contentsOf: storeURL) == garbage)
    }
}
