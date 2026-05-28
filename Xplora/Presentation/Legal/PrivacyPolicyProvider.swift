//
//  PrivacyPolicyProvider.swift
//  Xplora
//

import Foundation

enum PrivacyPolicyProvider {
    private static let resourceName = "privacy-policy"
    private static let resourceExtension = "md"

    static func load(bundle: Bundle = .main) throws -> LegalDocument {
        guard let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) else {
            throw LegalDocumentError.resourceNotFound
        }

        guard let body = try? String(contentsOf: url, encoding: .utf8) else {
            throw LegalDocumentError.unreadable
        }

        return LegalDocument(
            title: L10n.Profile.Privacy.title,
            markdownBody: body
        )
    }
}
