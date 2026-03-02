//
//  NoteModuleOutput.swift
//  Xplora
//

import Foundation

protocol NoteModuleOutput: AnyObject {
    func noteModuleDidSave(note: Note)
    func noteModuleDidDelete(noteId: String)
}
