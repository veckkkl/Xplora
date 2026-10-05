//
//  AppLaunchRoute.swift
//  Xplora
//

import Foundation
import os

enum AppLaunchRoute: Equatable {
    case onboarding
    case mainApp
    /// A stored user exists but can't be read. Onboarding would overwrite
    /// it, so the user decides between retrying and resetting local data.
    case authRecovery
}

enum AppLaunchRouteResolver {
    static func resolve(getCurrentUser: GetCurrentUserUseCase) -> AppLaunchRoute {
        do {
            return try getCurrentUser.execute() == nil ? .onboarding : .mainApp
        } catch {
            let nsError = error as NSError
            Logger.storage.error(
                "Current user read failed domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
            )
            return .authRecovery
        }
    }
}
