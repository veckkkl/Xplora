//
//  NoteEditorNavigationBarConfigurator.swift
//  Xplora
//

import UIKit

/// Builds and configures the note editor's navigation bar items.
///
/// The configurator only produces UI items based on input state and
/// callbacks. The view controller is responsible for assigning them to
/// `navigationItem` and owning the underlying target objects/selectors.
enum NoteEditorNavigationBarConfigurator {
    struct MenuHandlers {
        let onToggleBookmark: () -> Void
        let onTapSearch: () -> Void
        let onConfirmDelete: () -> Void
    }

    /// Applies the transparent appearance used by the note editor screen.
    static func applyTransparentAppearance(
        to navigationItem: UINavigationItem,
        navigationBar: UINavigationBar?
    ) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationBar?.isTranslucent = true
    }

    /// Builds the custom chevron back button.
    static func makeBackButton(target: Any, action: Selector) -> UIBarButtonItem {
        UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: target,
            action: action
        )
    }

    /// Builds the right-hand navigation items for the current state.
    ///
    /// In edit mode the order is `[done, menu]`; otherwise `[menu, edit]`.
    static func makeRightItems(
        state: NoteViewState,
        editTarget: Any,
        editAction: Selector,
        saveTarget: Any,
        saveAction: Selector,
        menuHandlers: MenuHandlers
    ) -> [UIBarButtonItem] {
        let editButton = UIBarButtonItem(
            title: L10n.Common.edit,
            style: .plain,
            target: editTarget,
            action: editAction
        )

        let menu = makeMenu(state: state, handlers: menuHandlers)
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease"),
            menu: menu
        )

        if state.mode == .edit {
            let doneButton = makeSystemCheckmarkButton(
                isEnabled: state.isSaveEnabled && !state.isLoading,
                target: saveTarget,
                action: saveAction
            )
            return [doneButton, menuButton]
        } else {
            return [menuButton, editButton]
        }
    }

    // MARK: - Private

    private static func makeMenu(
        state: NoteViewState,
        handlers: MenuHandlers
    ) -> UIMenu {
        let bookmarkTitle = state.isBookmarked
            ? L10n.Notes.Editor.Menu.Bookmark.remove
            : L10n.Notes.Editor.Menu.Bookmark.add
        let bookmarkImageName = state.isBookmarked ? "bookmark.fill" : "bookmark"
        let bookmarkAction = UIAction(
            title: bookmarkTitle,
            image: UIImage(systemName: bookmarkImageName),
            state: state.isBookmarked ? .on : .off
        ) { _ in
            handlers.onToggleBookmark()
        }
        bookmarkAction.attributes = state.canToggleBookmark ? [] : [.disabled]

        let searchAction = UIAction(
            title: L10n.Notes.Editor.Menu.find,
            image: UIImage(systemName: "magnifyingglass")
        ) { _ in
            handlers.onTapSearch()
        }
        searchAction.attributes = (state.canSearch && state.mode != .edit) ? [] : [.disabled]

        let deleteAction = UIAction(
            title: L10n.Notes.Editor.Menu.delete,
            image: UIImage(systemName: "trash"),
            attributes: [.destructive]
        ) { _ in
            handlers.onConfirmDelete()
        }
        deleteAction.attributes = state.isDeleteVisible ? [.destructive] : [.disabled, .destructive]

        return UIMenu(title: "", children: [bookmarkAction, searchAction, deleteAction])
    }

    private static func makeSystemCheckmarkButton(
        isEnabled: Bool,
        target: Any,
        action: Selector
    ) -> UIBarButtonItem {
        let image = UIImage(systemName: "checkmark") ?? UIImage()
        let button = UIButton.systemButton(with: image, target: target, action: action)
        button.isEnabled = isEnabled
        button.tintColor = isEnabled ? .systemBlue : .tertiaryLabel
        let item = UIBarButtonItem(customView: button)
        item.isEnabled = isEnabled
        return item
    }
}
