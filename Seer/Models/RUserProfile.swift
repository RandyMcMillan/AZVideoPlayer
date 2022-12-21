//
//  RUserProfile.swift
//  Seer
//
//  Created by Jacob Davis on 11/2/22.
//

import Foundation
import RealmSwift
import NostrKit

class RUserProfile: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var publicKey: String
    @Persisted var name: String
    @Persisted var about: String
    @Persisted var picture: String
    @Persisted var createdAt: Date
    @Persisted var selected: Bool
    
    var avatarUrl: URL? {
        return URL(string: picture)
    }
    
    var aboutFormatted: AttributedString? {
        if !about.isEmpty {
            return try? AttributedString(markdown: about,
                                         options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        }
        return nil
    }
    
    var bech32PublicKey: String {
        KeyPair.bech32PublicKey(fromHex: publicKey) ?? publicKey
    }
    
    func getLatestMessage() -> REncryptedDirectMessage? {
        return try? Realm().objects(REncryptedDirectMessage.self)
            .where({ $0.userProfile.publicKey == publicKey || $0.toUserProfile.publicKey == publicKey })
            .sorted(by: { $0.createdAt > $1.createdAt })
            .first
    }
    
    func hasContacted() -> Bool {
        if let realm = try? Realm() {
            if let selectedOwnerUserProfile = realm.objects(ROwnedUserProfile.self).first(where: { $0.selected == true }) {
                return realm.objects(REncryptedDirectMessage.self).first(where: { $0.publicKey == selectedOwnerUserProfile.publicKey && $0.toUserProfile?.publicKey == publicKey }) != nil
            }
        }
        return false
    }
    
}

extension RUserProfile {
    
    static func create(with event: Event) -> RUserProfile? {
        do {
            let decoder = JSONDecoder()
            let eventData = try decoder.decode(NostrRelay.SetMetaDataEventData.self, from: Data(event.content.utf8))
            return RUserProfile(value: ["publicKey": event.publicKey,
                                        "name": eventData.name ?? "",
                                        "about": eventData.about ?? "",
                                        "picture": eventData.picture ?? "",
                                        "createdAt": Date(timeIntervalSince1970: Double(event.createdAt.timestamp)),
                                       ])
        } catch {
            print(error)
            return nil
        }
    }
    
    static func createEmpty(withPublicKey publicKey: String) -> RUserProfile {
        return RUserProfile(value: ["publicKey": publicKey])
    }
    
    static let preview = RUserProfile(value: [
        "publicKey": "lasdfjenandlfieasdnf",
        "name": "Zao",
        "about": "Founder and CEO at Galaxoid Labs. Working on lots of cool stuff around Bitcoin.",
        "picture": "",
        "createdAt": Date(),
    ])
}
