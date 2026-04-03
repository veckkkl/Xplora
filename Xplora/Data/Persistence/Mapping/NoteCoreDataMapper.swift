//
//  NoteCoreDataMapper.swift
//  Xplora
//

import CoreData
import Foundation

enum NoteCoreDataMapper {
    static func toDomain(_ managedObject: CDNote) -> Note {
        let photosSet = managedObject.photos as? Set<CDNotePhoto> ?? []
        let mappedPhotos: [NotePhoto] = photosSet
            .map { photo in
                NotePhoto(
                    id: photo.id ?? UUID().uuidString,
                    localPath: photo.localPath ?? "",
                    createdAt: photo.createdAt ?? Date(),
                    orderIndex: Int(photo.orderIndex)
                )
            }
            .sorted { $0.orderIndex < $1.orderIndex }

        return Note(
            id: managedObject.id ?? UUID().uuidString,
            title: managedObject.title,
            text: managedObject.text ?? "",
            createdAt: managedObject.createdAt ?? Date(),
            updatedAt: managedObject.updatedAt ?? Date(),
            isBookmarked: managedObject.isBookmarked,
            location: domainLocation(from: managedObject),
            photos: mappedPhotos,
            dateRangeText: nil
        )
    }

    static func upsert(_ note: Note, into managedObject: CDNote, in context: NSManagedObjectContext) {
        managedObject.id = note.id
        managedObject.title = note.title
        managedObject.text = note.text
        managedObject.createdAt = note.createdAt
        managedObject.updatedAt = note.updatedAt
        managedObject.isBookmarked = note.isBookmarked
        if let location = note.location {
            managedObject.placeName = location.placeName
            managedObject.city = location.city
            managedObject.country = location.country
            managedObject.setValue(location.latitude, forKey: #keyPath(CDNote.latitude))
            managedObject.setValue(location.longitude, forKey: #keyPath(CDNote.longitude))
        } else {
            managedObject.placeName = nil
            managedObject.city = nil
            managedObject.country = nil
            managedObject.setValue(nil, forKey: #keyPath(CDNote.latitude))
            managedObject.setValue(nil, forKey: #keyPath(CDNote.longitude))
        }

        let photosSet = managedObject.photos as? Set<CDNotePhoto> ?? []
        let existingPhotos: [String: CDNotePhoto] = Dictionary(uniqueKeysWithValues: photosSet.compactMap { photo in
            guard let id = photo.id else { return nil }
            return (id, photo)
        })
        var updatedPhotos = Set<CDNotePhoto>()

        for domainPhoto in note.photos {
            let managedPhoto = existingPhotos[domainPhoto.id] ?? CDNotePhoto(context: context)
            managedPhoto.id = domainPhoto.id
            managedPhoto.localPath = domainPhoto.localPath
            managedPhoto.createdAt = domainPhoto.createdAt
            managedPhoto.orderIndex = Int32(domainPhoto.orderIndex)
            managedPhoto.note = managedObject
            updatedPhotos.insert(managedPhoto)
        }

        let incomingIDs = Set(note.photos.map(\.id))
        for existingPhoto in photosSet where !incomingIDs.contains(existingPhoto.id ?? "") {
            context.delete(existingPhoto)
        }

        managedObject.photos = NSSet(set: updatedPhotos)
    }

    private static func domainLocation(from managedObject: CDNote) -> NoteLocation? {
        let placeName = (managedObject.placeName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let city = (managedObject.city ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let country = (managedObject.country ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let latitude = doubleValue(for: #keyPath(CDNote.latitude), in: managedObject)
        let longitude = doubleValue(for: #keyPath(CDNote.longitude), in: managedObject)

        guard let latitude, let longitude else { return nil }
        let hasAnyText = !placeName.isEmpty || !city.isEmpty || !country.isEmpty
        guard hasAnyText || latitude != 0 || longitude != 0 else { return nil }

        return NoteLocation(
            placeName: placeName,
            city: city,
            country: country,
            latitude: latitude,
            longitude: longitude
        )
    }

    private static func doubleValue(for keyPath: String, in managedObject: CDNote) -> Double? {
        let rawValue = managedObject.value(forKey: keyPath)

        if let number = rawValue as? NSNumber {
            return number.doubleValue
        }

        if let double = rawValue as? Double {
            return double
        }

        return nil
    }
}
