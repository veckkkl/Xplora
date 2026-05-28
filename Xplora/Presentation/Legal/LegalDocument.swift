//
//  LegalDocument.swift
//  Xplora
//

import Foundation

struct LegalDocument: Equatable {
    let title: String
    let markdownBody: String
}

enum LegalDocumentError: Error {
    case resourceNotFound
    case unreadable
}
