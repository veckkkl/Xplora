//
//  NoteRouter.swift
//  Xplora
//

import UIKit

protocol NoteRouter: AnyObject {
    func showNote(noteId: String?, coordinate: LocationCoordinate?, output: NoteModuleOutput?)
    func closeNote()
}

@MainActor
final class NoteRouterImpl: NoteRouter {
    private let navigationController: UINavigationController
    private let builder: NoteModuleBuilder

    init(navigationController: UINavigationController, builder: NoteModuleBuilder) {
        self.navigationController = navigationController
        self.builder = builder
    }

    func showNote(noteId: String?, coordinate: LocationCoordinate?, output: NoteModuleOutput?) {
        let viewController = builder.build(noteId: noteId, coordinate: coordinate, output: output, router: self)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }

    func closeNote() {
        navigationController.popViewController(animated: true)
    }
}
