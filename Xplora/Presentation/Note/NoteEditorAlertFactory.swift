//
//  NoteEditorAlertFactory.swift
//  Xplora
//

import UIKit

/// Builds `UIAlertController` instances used by the note editor.
///
/// The factory only constructs alerts; presenting them and applying
/// presentation-context details (e.g. popover anchors) remains the
/// responsibility of the view controller.
enum NoteEditorAlertFactory {
    static func makeErrorAlert(message: String) -> UIAlertController {
        let alert = UIAlertController(
            title: L10n.Notes.Editor.Alert.Error.title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        return alert
    }

    static func makeDeleteConfirmation(onDelete: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title: L10n.Notes.Editor.Alert.Delete.title,
            message: L10n.Notes.Editor.Alert.Delete.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.Common.delete, style: .destructive) { _ in
            onDelete()
        })
        return alert
    }

    static func makeExitConfirmation(
        isSaveEnabled: Bool,
        onDiscard: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: L10n.Notes.Editor.Alert.Unsaved.title,
            message: L10n.Notes.Editor.Alert.Unsaved.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.Common.discard, style: .destructive) { _ in
            onDiscard()
        })
        let saveAction = UIAlertAction(title: L10n.Common.save, style: .default) { _ in
            onSave()
        }
        saveAction.isEnabled = isSaveEnabled
        alert.addAction(saveAction)
        return alert
    }

    static func makePhotoSourceActionSheet(
        onCamera: @escaping () -> Void,
        onLibrary: @escaping () -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: L10n.Notes.Editor.Photo.Add.title,
            message: nil,
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: L10n.Notes.Editor.Photo.Source.camera, style: .default) { _ in
            onCamera()
        })
        alert.addAction(UIAlertAction(title: L10n.Notes.Editor.Photo.Source.library, style: .default) { _ in
            onLibrary()
        })
        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel))
        return alert
    }
}
