//
//  RTextNote.swift
//  Seer
//
//  Created by Jacob Davis on 11/2/22.
//

import Foundation
import RealmSwift
import NostrKit

class RTextNote: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var eventId: String
    @Persisted var publicKey: String
    @Persisted var content: String
    @Persisted var createdAt: Date
    
    @Persisted var userProfile: RUserProfile?
    @Persisted var rootParentEventId: String?
    @Persisted var parentEventId: String?
    
    var isTopLevelNote: Bool {
        return rootParentEventId == nil && parentEventId == nil
    }
}

class TextNoteVM: Projection<RTextNote>, ObjectKeyIdentifiable {
    @Projected(\RTextNote.publicKey) var eventId
    @Projected(\RTextNote.publicKey) var publicKey
    @Projected(\RTextNote.content) var content
    @Projected(\RTextNote.createdAt) var createdAt
    @Projected(\RTextNote.userProfile) var userProfile
    @Projected(\RTextNote.rootParentEventId) var rootParentEventId
    @Projected(\RTextNote.parentEventId) var parentEventId
    
    var isTopLevelNote: Bool {
        return rootParentEventId == nil && parentEventId == nil
    }
    
    var contentFormatted: AttributedString? {
        if !content.isEmpty {
            return try? AttributedString(markdown: content,
                                         options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        }
        return nil
    }
    
    var imageUrl: URL? {
        if let content = contentFormatted {
            for run in content.runs {
                if let link = run.link {
                    if link.absoluteURL.isImageType() {
                        return link.absoluteURL
                    }
                }
            }
        }
        return nil
    }
    
    var videoUrl: URL? {
        if let content = contentFormatted {
            for run in content.runs {
                if let link = run.link {
                    if link.absoluteURL.isVideoType() {
                        return link.absoluteURL
                    }
                }
            }
        }
        return nil
    }
}

extension RTextNote {
    
    static func create(with event: Event) -> RTextNote {
        return RTextNote(value: ["eventId": event.id, "publicKey": event.publicKey,
                                 "content": event.content, "createdAt": Date(timeIntervalSince1970: Double(event.createdAt.timestamp))])
        
    }
    
}
