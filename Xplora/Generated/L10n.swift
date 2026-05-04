// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum Common {
    /// Cancel
    internal static let cancel = L10n.tr("Localizable", "common.cancel", fallback: "Cancel")
    /// Delete
    internal static let delete = L10n.tr("Localizable", "common.delete", fallback: "Delete")
    /// Discard
    internal static let discard = L10n.tr("Localizable", "common.discard", fallback: "Discard")
    /// Edit
    internal static let edit = L10n.tr("Localizable", "common.edit", fallback: "Edit")
    /// Error
    internal static let error = L10n.tr("Localizable", "common.error", fallback: "Error")
    /// Map
    internal static let map = L10n.tr("Localizable", "common.map", fallback: "Map")
    /// OK
    internal static let ok = L10n.tr("Localizable", "common.ok", fallback: "OK")
    /// Remove photo
    internal static let removePhoto = L10n.tr("Localizable", "common.remove_photo", fallback: "Remove photo")
    /// Save
    internal static let save = L10n.tr("Localizable", "common.save", fallback: "Save")
  }
  internal enum Map {
    internal enum Actions {
      /// Notes
      internal static let notes = L10n.tr("Localizable", "map.actions.notes", fallback: "Notes")
    }
    internal enum Marker {
      /// Pinned note
      internal static let pinnedNote = L10n.tr("Localizable", "map.marker.pinned_note", fallback: "Pinned note")
    }
    internal enum Preview {
      /// Open note to see details.
      internal static let openNoteHint = L10n.tr("Localizable", "map.preview.open_note_hint", fallback: "Open note to see details.")
    }
  }
  internal enum Notes {
    internal enum Editor {
      internal enum Alert {
        internal enum Delete {
          /// This action can't be undone.
          internal static let message = L10n.tr("Localizable", "notes.editor.alert.delete.message", fallback: "This action can't be undone.")
          /// Delete note?
          internal static let title = L10n.tr("Localizable", "notes.editor.alert.delete.title", fallback: "Delete note?")
        }
        internal enum Error {
          /// Something went wrong
          internal static let title = L10n.tr("Localizable", "notes.editor.alert.error.title", fallback: "Something went wrong")
        }
        internal enum Unsaved {
          /// You have unsaved changes.
          internal static let message = L10n.tr("Localizable", "notes.editor.alert.unsaved.message", fallback: "You have unsaved changes.")
          /// Save changes?
          internal static let title = L10n.tr("Localizable", "notes.editor.alert.unsaved.title", fallback: "Save changes?")
        }
      }
      internal enum Date {
        /// From
        internal static let from = L10n.tr("Localizable", "notes.editor.date.from", fallback: "From")
        /// To
        internal static let to = L10n.tr("Localizable", "notes.editor.date.to", fallback: "To")
      }
      internal enum Error {
        /// Couldn't update the bookmark. Please try again.
        internal static let bookmark = L10n.tr("Localizable", "notes.editor.error.bookmark", fallback: "Couldn't update the bookmark. Please try again.")
        /// Couldn't delete the note. Please try again.
        internal static let delete = L10n.tr("Localizable", "notes.editor.error.delete", fallback: "Couldn't delete the note. Please try again.")
        /// Couldn't load the note. Please try again.
        internal static let load = L10n.tr("Localizable", "notes.editor.error.load", fallback: "Couldn't load the note. Please try again.")
        /// Couldn't save the note. Please try again.
        internal static let save = L10n.tr("Localizable", "notes.editor.error.save", fallback: "Couldn't save the note. Please try again.")
        internal enum Photo {
          /// Couldn't add photos. Please try again.
          internal static let addFailed = L10n.tr("Localizable", "notes.editor.error.photo.add_failed", fallback: "Couldn't add photos. Please try again.")
          /// Some photos were skipped because they are already added.
          internal static let skippedDuplicates = L10n.tr("Localizable", "notes.editor.error.photo.skipped_duplicates", fallback: "Some photos were skipped because they are already added.")
          /// Some photos couldn't be added.
          internal static let skippedFailed = L10n.tr("Localizable", "notes.editor.error.photo.skipped_failed", fallback: "Some photos couldn't be added.")
          internal enum Duplicate {
            /// This photo is already added.
            internal static let single = L10n.tr("Localizable", "notes.editor.error.photo.duplicate.single", fallback: "This photo is already added.")
          }
        }
      }
      internal enum Menu {
        /// Delete Note
        internal static let delete = L10n.tr("Localizable", "notes.editor.menu.delete", fallback: "Delete Note")
        /// Find in Note
        internal static let find = L10n.tr("Localizable", "notes.editor.menu.find", fallback: "Find in Note")
        internal enum Bookmark {
          /// Add Bookmark
          internal static let add = L10n.tr("Localizable", "notes.editor.menu.bookmark.add", fallback: "Add Bookmark")
          /// Remove Bookmark
          internal static let remove = L10n.tr("Localizable", "notes.editor.menu.bookmark.remove", fallback: "Remove Bookmark")
        }
      }
      internal enum Photo {
        /// You can add up to %d photos.
        internal static func limit(_ p1: Int) -> String {
          return L10n.tr("Localizable", "notes.editor.photo.limit", p1, fallback: "You can add up to %d photos.")
        }
        internal enum Add {
          /// Add Photo
          internal static let title = L10n.tr("Localizable", "notes.editor.photo.add.title", fallback: "Add Photo")
        }
        internal enum Camera {
          /// Camera is not available on this device.
          internal static let unavailable = L10n.tr("Localizable", "notes.editor.photo.camera.unavailable", fallback: "Camera is not available on this device.")
        }
        internal enum Picker {
          /// %d/%d
          internal static func counter(_ p1: Int, _ p2: Int) -> String {
            return L10n.tr("Localizable", "notes.editor.photo.picker.counter", p1, p2, fallback: "%d/%d")
          }
        }
        internal enum Source {
          /// Camera
          internal static let camera = L10n.tr("Localizable", "notes.editor.photo.source.camera", fallback: "Camera")
          /// Photo Library
          internal static let library = L10n.tr("Localizable", "notes.editor.photo.source.library", fallback: "Photo Library")
        }
      }
      internal enum Search {
        /// Search in note
        internal static let placeholder = L10n.tr("Localizable", "notes.editor.search.placeholder", fallback: "Search in note")
      }
      internal enum Text {
        /// Write your note...
        internal static let placeholder = L10n.tr("Localizable", "notes.editor.text.placeholder", fallback: "Write your note...")
      }
      internal enum Title {
        /// Title
        internal static let placeholder = L10n.tr("Localizable", "notes.editor.title.placeholder", fallback: "Title")
      }
    }
    internal enum List {
      /// Notes
      internal static let title = L10n.tr("Localizable", "notes.list.title", fallback: "Notes")
      internal enum Empty {
        /// No notes yet
        internal static let title = L10n.tr("Localizable", "notes.list.empty.title", fallback: "No notes yet")
      }
      internal enum Error {
        /// Couldn't load notes. Please try again.
        internal static let load = L10n.tr("Localizable", "notes.list.error.load", fallback: "Couldn't load notes. Please try again.")
      }
    }
    internal enum Location {
      internal enum Search {
        /// Search location
        internal static let placeholder = L10n.tr("Localizable", "notes.location.search.placeholder", fallback: "Search location")
        /// Location
        internal static let title = L10n.tr("Localizable", "notes.location.search.title", fallback: "Location")
        internal enum Error {
          /// Couldn't fetch this location. Try another one.
          internal static let message = L10n.tr("Localizable", "notes.location.search.error.message", fallback: "Couldn't fetch this location. Try another one.")
          /// Location unavailable
          internal static let title = L10n.tr("Localizable", "notes.location.search.error.title", fallback: "Location unavailable")
        }
      }
      internal enum Section {
        /// Add location
        internal static let add = L10n.tr("Localizable", "notes.location.section.add", fallback: "Add location")
      }
    }
    internal enum Presentation {
      /// Untitled
      internal static let untitled = L10n.tr("Localizable", "notes.presentation.untitled", fallback: "Untitled")
    }
  }
  internal enum Placeholder {
    /// %@ (stub)
    internal static func stubFormat(_ p1: Any) -> String {
      return L10n.tr("Localizable", "placeholder.stub_format", String(describing: p1), fallback: "%@ (stub)")
    }
  }
  internal enum Tab {
    /// Profile
    internal static let profile = L10n.tr("Localizable", "tab.profile", fallback: "Profile")
    /// Statistics
    internal static let statistics = L10n.tr("Localizable", "tab.statistics", fallback: "Statistics")
    /// Timeline
    internal static let timeline = L10n.tr("Localizable", "tab.timeline", fallback: "Timeline")
    /// Wishlist
    internal static let wishlist = L10n.tr("Localizable", "tab.wishlist", fallback: "Wishlist")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
