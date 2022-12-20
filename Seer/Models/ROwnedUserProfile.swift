//
//  ROwnedUserProfile.swift
//  Seer
//
//  Created by Jacob Davis on 12/19/22.
//

import Foundation
import RealmSwift
import NostrKit

class ROwnedUserProfile: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var publicKey: String
    @Persisted var selected: Bool
    
    var userProfile: RUserProfile? {
        return try? Realm().object(ofType: RUserProfile.self, forPrimaryKey: publicKey)
    }
}

extension ROwnedUserProfile {

    static func create(withPublicKey publicKey: String) -> ROwnedUserProfile {
        return ROwnedUserProfile(value: ["publicKey": publicKey, "selected": false])
    }
    
    static let preview = ROwnedUserProfile(value: [
        "publicKey": "lasdfjenandlfieasdnf",
        "selected": true
    ])
}
