//
//  NotePhotoPickerPresenter.swift
//  Xplora
//

import PhotosUI
import UIKit

/// Coordinates presentation of the photo source action sheet, the camera
/// picker and the photo library picker, including their delegate callbacks.
///
/// The owner (typically a view controller) retains the presenter strongly so
/// that picker delegate callbacks survive long enough to reach
/// `onCapturePhoto` / `onPhotoLibrarySelection`.
///
/// The presenter does not own any business state. It exposes a `Context`
/// computed at call time and emits user actions via closures, which the
/// view controller forwards to its view model.
final class NotePhotoPickerPresenter: NSObject {
    struct Context {
        let canAddPhoto: Bool
        let photoURLsCount: Int
        let preselectedAssetIdentifiers: [String]
    }

    weak var presentingViewController: UIViewController?
    weak var sourceView: UIView?

    var onCapturePhoto: ((UIImage) -> Void)?
    var onPhotoLibrarySelection: (([PHPickerResult]) -> Void)?
    var onError: ((String) -> Void)?

    private let maxPhotoCount: Int

    init(maxPhotoCount: Int) {
        self.maxPhotoCount = maxPhotoCount
        super.init()
    }

    func presentSource(context: Context) {
        guard let presentingViewController else { return }

        if !context.canAddPhoto {
            onError?(L10n.Notes.Editor.Photo.limit(maxPhotoCount))
            return
        }

        let alert = NoteEditorAlertFactory.makePhotoSourceActionSheet(
            onCamera: { [weak self] in self?.presentCamera(context: context) },
            onLibrary: { [weak self] in self?.presentLibrary(context: context) }
        )

        if let popover = alert.popoverPresentationController, let sourceView {
            popover.sourceView = sourceView
            popover.sourceRect = CGRect(
                x: sourceView.bounds.midX,
                y: sourceView.bounds.midY,
                width: 1,
                height: 1
            )
        }
        presentingViewController.present(alert, animated: true)
    }

    // MARK: - Private

    private func presentCamera(context: Context) {
        guard let presentingViewController else { return }

        if !context.canAddPhoto {
            onError?(L10n.Notes.Editor.Photo.limit(maxPhotoCount))
            return
        }

        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            onError?(L10n.Notes.Editor.Photo.Camera.unavailable)
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = false
        presentingViewController.present(picker, animated: true)
    }

    private func presentLibrary(context: Context) {
        guard let presentingViewController else { return }

        let remainingSlots = maxPhotoCount - context.photoURLsCount
        guard remainingSlots > 0 else {
            onError?(L10n.Notes.Editor.Photo.limit(maxPhotoCount))
            return
        }

        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = context.preselectedAssetIdentifiers.count + remainingSlots
        configuration.selection = .default
        configuration.filter = .images
        configuration.preselectedAssetIdentifiers = context.preselectedAssetIdentifiers

        let picker = PHPickerViewController(configuration: configuration)
        picker.title = L10n.Notes.Editor.Photo.Picker.counter(context.photoURLsCount, maxPhotoCount)
        picker.delegate = self
        presentingViewController.present(picker, animated: true)
    }
}

extension NotePhotoPickerPresenter: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        onPhotoLibrarySelection?(results)
    }
}

extension NotePhotoPickerPresenter: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        onCapturePhoto?(image)
    }
}
