//
//  NoteEditorKeyboardObserver.swift
//  Xplora
//

import UIKit

/// Observes `UIResponder.keyboardWillShowNotification` /
/// `keyboardWillHideNotification` and forwards them as closure callbacks.
///
/// Encapsulates token storage and removal so the view controller does not
/// have to manage observers manually. The owner retains the observer
/// strongly; when the owner is deallocated, the observer's `deinit`
/// unsubscribes from `NotificationCenter`.
final class NoteEditorKeyboardObserver {
    var onWillShow: (() -> Void)?
    var onWillHide: (() -> Void)?

    private var tokens: [NSObjectProtocol] = []

    func start() {
        guard tokens.isEmpty else { return }
        let willShow = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onWillShow?()
        }
        let willHide = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onWillHide?()
        }
        tokens = [willShow, willHide]
    }

    func stop() {
        tokens.forEach { NotificationCenter.default.removeObserver($0) }
        tokens.removeAll()
    }

    deinit {
        stop()
    }
}
