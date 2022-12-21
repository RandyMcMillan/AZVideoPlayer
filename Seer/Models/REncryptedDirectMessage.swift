//
//  REncryptedDirectMessage.swift
//  Seer
//
//  Created by Jacob Davis on 12/19/22.
//

import Foundation
import NostrKit
import RealmSwift
import CryptoKit

class REncryptedDirectMessage: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var eventId: String
    @Persisted var publicKey: String
    @Persisted var content: String
    @Persisted var createdAt: Date
    
    @Persisted var userProfile: RUserProfile?
    @Persisted var toUserProfile: RUserProfile?
    
    var otherUserProfile: RUserProfile? {
        if let selectedOwnerUserProfile = try? Realm().objects(ROwnedUserProfile.self).first(where: { $0.selected == true }) {
            if selectedOwnerUserProfile.publicKey == userProfile?.publicKey {
                return toUserProfile
            } else {
                return userProfile
            }
        }
        return nil
    }
    
    func decryptedContent() -> String {
        if let ownerUserProfile = NostrData.shared.selectedOwnerUserProfile,
            userProfile?.publicKey == ownerUserProfile.publicKey || toUserProfile?.publicKey == ownerUserProfile.publicKey {
            
            var otherPublicKey: String?
            if userProfile?.publicKey == ownerUserProfile.publicKey {
                otherPublicKey = toUserProfile?.publicKey
            } else {
                otherPublicKey = userProfile?.publicKey
            }
            
            if let otherPublicKey {
                var decryptedMessage: String?
                let ourPrivateKey = NostrData.shared.privateKey(forPublicKey: ownerUserProfile.publicKey)
                decryptedMessage = KeyPair.decryptDirectMessageContent(withPrivateKey: ourPrivateKey, pubkey: otherPublicKey, content: content)
                
                return decryptedMessage ?? content
            }
        }
        return content
    }
}

extension REncryptedDirectMessage {
    static func create(with event: Event) -> REncryptedDirectMessage {
        return REncryptedDirectMessage(value: ["eventId": event.id, "publicKey": event.publicKey,
                                      "content": event.content, "createdAt": Date(timeIntervalSince1970: Double(event.createdAt.timestamp))])
    }
}
