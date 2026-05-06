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
  internal enum Profile {
    /// Profile
    internal static let tabTitle = L10n.tr("Localizable", "profile.tab.title", fallback: "Profile")
    /// Settings
    internal static let title = L10n.tr("Localizable", "profile.title", fallback: "Settings")
    internal enum About {
      /// Build
      internal static let build = L10n.tr("Localizable", "profile.about.build", fallback: "Build")
      /// Developer Resources
      internal static let developerResourcesTitle = L10n.tr("Localizable", "profile.about.developer_resources_title", fallback: "Developer Resources")
      /// Designed for capturing places, memories and trips.
      internal static let footer = L10n.tr("Localizable", "profile.about.footer", fallback: "Designed for capturing places, memories and trips.")
      /// GitHub Repository
      internal static let githubRepository = L10n.tr("Localizable", "profile.about.github_repository", fallback: "GitHub Repository")
      /// About Xplora screen will be implemented in the next step.
      internal static let placeholder = L10n.tr("Localizable", "profile.about.placeholder", fallback: "About Xplora screen will be implemented in the next step.")
      /// README / Guide
      internal static let readmeGuide = L10n.tr("Localizable", "profile.about.readme_guide", fallback: "README / Guide")
      /// Travel journal for your experiences
      internal static let subtitle = L10n.tr("Localizable", "profile.about.subtitle", fallback: "Travel journal for your experiences")
      /// About Xplora
      internal static let title = L10n.tr("Localizable", "profile.about.title", fallback: "About Xplora")
      /// Version
      internal static let version = L10n.tr("Localizable", "profile.about.version", fallback: "Version")
      /// Version %@ · Build %@
      internal static func versionBuild(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "profile.about.version_build_format", String(describing: p1), String(describing: p2), fallback: "Version %@ · Build %@")
      }
      internal enum Card {
        /// Xplora helps you save places, memories and travel stories.
        internal static let aboutText = L10n.tr("Localizable", "profile.about.card.about_text", fallback: "Xplora helps you save places, memories and travel stories.")
        /// About Xplora
        internal static let aboutTitle = L10n.tr("Localizable", "profile.about.card.about_title", fallback: "About Xplora")
        /// Save places, keep travel notes, mark important memories and view your journeys on the map.
        internal static let featuresText = L10n.tr("Localizable", "profile.about.card.features_text", fallback: "Save places, keep travel notes, mark important memories and view your journeys on the map.")
        /// Features
        internal static let featuresTitle = L10n.tr("Localizable", "profile.about.card.features_title", fallback: "Features")
        /// Built with UIKit, MVVM, Clean Architecture, SnapKit and local data storage.
        internal static let technologiesText = L10n.tr("Localizable", "profile.about.card.technologies_text", fallback: "Built with UIKit, MVVM, Clean Architecture, SnapKit and local data storage.")
        /// Technologies
        internal static let technologiesTitle = L10n.tr("Localizable", "profile.about.card.technologies_title", fallback: "Technologies")
      }
    }
    internal enum Card {
      /// Apple ID, iCloud, and more
      internal static let subtitle = L10n.tr("Localizable", "profile.card.subtitle", fallback: "Apple ID, iCloud, and more")
    }
    internal enum Danger {
      /// Deleting data is permanent and cannot be undone.
      internal static let footnote = L10n.tr("Localizable", "profile.danger.footnote", fallback: "Deleting data is permanent and cannot be undone.")
    }
    internal enum Delete {
      /// This action cannot be undone.
      internal static let confirmationMessage = L10n.tr("Localizable", "profile.delete.confirmation_message", fallback: "This action cannot be undone.")
      /// Delete Data?
      internal static let confirmationTitle = L10n.tr("Localizable", "profile.delete.confirmation_title", fallback: "Delete Data?")
      /// Data deletion will be implemented in the next step.
      internal static let stubMessage = L10n.tr("Localizable", "profile.delete.stub_message", fallback: "Data deletion will be implemented in the next step.")
      /// Not Available Yet
      internal static let stubTitle = L10n.tr("Localizable", "profile.delete.stub_title", fallback: "Not Available Yet")
    }
    internal enum Details {
      /// Profile details screen will be implemented in the next step.
      internal static let placeholder = L10n.tr("Localizable", "profile.details.placeholder", fallback: "Profile details screen will be implemented in the next step.")
      /// Profile
      internal static let title = L10n.tr("Localizable", "profile.details.title", fallback: "Profile")
    }
    internal enum Item {
      /// About Xplora
      internal static let aboutXplora = L10n.tr("Localizable", "profile.item.about_xplora", fallback: "About Xplora")
      /// Delete Data
      internal static let deleteData = L10n.tr("Localizable", "profile.item.delete_data", fallback: "Delete Data")
      /// Language
      internal static let language = L10n.tr("Localizable", "profile.item.language", fallback: "Language")
      /// Privacy Policy
      internal static let privacyPolicy = L10n.tr("Localizable", "profile.item.privacy_policy", fallback: "Privacy Policy")
      /// Share with Friends
      internal static let shareWithFriends = L10n.tr("Localizable", "profile.item.share_with_friends", fallback: "Share with Friends")
    }
    internal enum Language {
      /// English
      internal static let english = L10n.tr("Localizable", "profile.language.english", fallback: "English")
      /// English
      internal static let nativeEnglish = L10n.tr("Localizable", "profile.language.native_english", fallback: "English")
      /// Русский
      internal static let nativeRussian = L10n.tr("Localizable", "profile.language.native_russian", fallback: "Русский")
      /// Russian
      internal static let russian = L10n.tr("Localizable", "profile.language.russian", fallback: "Russian")
    }
    internal enum LanguageSelection {
      /// Language selection will be implemented in the next step.
      internal static let placeholder = L10n.tr("Localizable", "profile.language_selection.placeholder", fallback: "Language selection will be implemented in the next step.")
      /// Language will be applied after restarting the app.
      internal static let restartMessage = L10n.tr("Localizable", "profile.language_selection.restart_message", fallback: "Language will be applied after restarting the app.")
      /// Language
      internal static let title = L10n.tr("Localizable", "profile.language_selection.title", fallback: "Language")
    }
    internal enum Privacy {
      /// Privacy Policy link will be added later.
      internal static let fallbackMessage = L10n.tr("Localizable", "profile.privacy.fallback_message", fallback: "Privacy Policy link will be added later.")
      /// Privacy Policy
      internal static let fallbackTitle = L10n.tr("Localizable", "profile.privacy.fallback_title", fallback: "Privacy Policy")
      /// Privacy Policy screen will be implemented in the next step.
      internal static let placeholder = L10n.tr("Localizable", "profile.privacy.placeholder", fallback: "Privacy Policy screen will be implemented in the next step.")
      /// Privacy Policy
      internal static let title = L10n.tr("Localizable", "profile.privacy.title", fallback: "Privacy Policy")
    }
    internal enum Section {
      /// App Settings
      internal static let appSettings = L10n.tr("Localizable", "profile.section.app_settings", fallback: "App Settings")
      /// Danger Zone
      internal static let dangerZone = L10n.tr("Localizable", "profile.section.danger_zone", fallback: "Danger Zone")
      /// Support
      internal static let support = L10n.tr("Localizable", "profile.section.support", fallback: "Support")
    }
    internal enum Share {
      /// Check out Xplora
      internal static let text = L10n.tr("Localizable", "profile.share.text", fallback: "Check out Xplora")
    }
    internal enum Stub {
      /// About screen will be implemented in the next step.
      internal static let about = L10n.tr("Localizable", "profile.stub.about", fallback: "About screen will be implemented in the next step.")
      /// Delete data flow will be implemented in the next step.
      internal static let deleteData = L10n.tr("Localizable", "profile.stub.delete_data", fallback: "Delete data flow will be implemented in the next step.")
      /// Language selection will be implemented in the next step.
      internal static let language = L10n.tr("Localizable", "profile.stub.language", fallback: "Language selection will be implemented in the next step.")
      /// Privacy Policy screen will be implemented in the next step.
      internal static let privacyPolicy = L10n.tr("Localizable", "profile.stub.privacy_policy", fallback: "Privacy Policy screen will be implemented in the next step.")
      /// Account details screen will be added in the next step.
      internal static let profileCard = L10n.tr("Localizable", "profile.stub.profile_card", fallback: "Account details screen will be added in the next step.")
      /// Share flow will be implemented in the next step.
      internal static let shareWithFriends = L10n.tr("Localizable", "profile.stub.share_with_friends", fallback: "Share flow will be implemented in the next step.")
      /// Not Available Yet
      internal static let title = L10n.tr("Localizable", "profile.stub.title", fallback: "Not Available Yet")
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
