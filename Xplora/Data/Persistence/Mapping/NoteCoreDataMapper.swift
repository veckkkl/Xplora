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
            location: NoteLocation(
                placeName: managedObject.placeName ?? "",
                city: managedObject.city ?? "",
                country: managedObject.country ?? "",
                latitude: managedObject.latitude,
                longitude: managedObject.longitude
            ),
            photos: mappedPhotos,
            dateRangeText: nil,
            headerTitle: nil
        )
    }

    static func apply(_ note: Note, to managedObject: CDNote, in context: NSManagedObjectContext) {
        managedObject.id = note.id
        managedObject.title = note.title
        managedObject.text = note.text
        managedObject.createdAt = note.createdAt
        managedObject.updatedAt = note.updatedAt
        managedObject.isBookmarked = note.isBookmarked
        managedObject.placeName = note.location.placeName
        managedObject.city = note.location.city
        managedObject.country = note.location.country
        managedObject.latitude = note.location.latitude
        managedObject.longitude = note.location.longitude

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
}
