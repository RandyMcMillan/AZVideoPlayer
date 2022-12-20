//
//  NostrData.swift
//  Seer
//
//  Created by Jacob Davis on 10/30/22.
//

import Foundation
import NostrKit
import RealmSwift

class NostrData: ObservableObject {

    static let lastSeenDefaultsKey = "lastSeenDefaultsKey"
    @Published var lastSeenDate = Date(timeIntervalSince1970: Double(UserDefaults.standard.integer(forKey: NostrData.lastSeenDefaultsKey)))
    
    var nostrRelays: [NostrRelay] = []
    
    @ObservedResults(ROwnedUserProfile.self) var ownedUserProfileResults
    var selectedOwnerUserProfile: ROwnedUserProfile? {
        ownedUserProfileResults.first(where: { $0.selected == true })
    }
    
    @ObservedResults(REncryptedDirectMessage.self) var directMessageResults
    var contactedUserProfiles: [RUserProfile] {
        let contactedMessages = directMessageResults.filter({ $0.userProfile?.publicKey == self.selectedOwnerUserProfile?.publicKey })
        let userProfileSet = Set(contactedMessages.compactMap({ $0.otherUserProfile }))
        return Array(userProfileSet).sorted(by: { ($0.getLatestMessage()?.createdAt ?? Date.now) > ($1.getLatestMessage()?.createdAt ?? Date.now) })
    }
    
    let realm: Realm
    static let shared = NostrData()
    
    private init() {
        if UserDefaults.standard.integer(forKey: NostrData.lastSeenDefaultsKey) == 0 {
            UserDefaults.standard.setValue(Timestamp(date: Date.now).timestamp, forKey: NostrData.lastSeenDefaultsKey)
            self.lastSeenDate = Date(timeIntervalSince1970: Double(UserDefaults.standard.integer(forKey: NostrData.lastSeenDefaultsKey)))
        }
        let config = Realm.Configuration(schemaVersion: 10)
        Realm.Configuration.defaultConfiguration = config
        self.realm = try! Realm()
        self.realm.autorefresh = true
        bootstrapRelays()
    }
    
    func initPreview() -> NostrData {
//        userProfiles = [UserProfile.preview]
//        textNotes = [TextNote.preview]
        return .shared
    }
    
    func bootstrapRelays() {
        self.nostrRelays.append(NostrRelay(urlString: "wss://relay.damus.io", realm: realm))
        //self.nostrRelays.append(NostrRelay(urlString: "wss://nostr-pub.wellorder.net", realm: realm))
        for relay in nostrRelays {
            relay.connect()
        }
    }
    
    func disconnect() {
        for relay in nostrRelays {
            relay.unsubscribe()
            relay.disconnect()
        }
    }
    
    func reconnect() {
        for relay in nostrRelays {
            if !relay.connected {
                relay.connect()
            }
        }
    }
    
    func fetchContactList(forPublicKey publicKey: String) {
        for relay in nostrRelays {
            relay.subscribeContactList(forPublicKey: publicKey)
        }
    }
    
    func updateLastSeenDate() {
        UserDefaults.standard.setValue(Timestamp(date: Date.now).timestamp, forKey: NostrData.lastSeenDefaultsKey)
        self.lastSeenDate = Date(timeIntervalSince1970: Double(UserDefaults.standard.integer(forKey: NostrData.lastSeenDefaultsKey)))
    }
    
    func selectedUserProfile() -> ROwnedUserProfile? {
        if let ownedUserProfile = realm.objects(ROwnedUserProfile.self).where({ $0.selected == true }).first {
            if let _ = privateKey(forPublicKey: ownedUserProfile.publicKey) {
                return ownedUserProfile
            }
        }
        return nil
    }

    func privateKey(forPublicKey publicKey: String) -> String? {
        if let pk = UserDefaults.standard.string(forKey: publicKey) {
            return pk
        }
        return nil
    }
    
    func save(privateKey: String, forPublicKey publicKey: String) {
        
        // TEMPORARY. Will save to keychain.
        UserDefaults.standard.set(privateKey, forKey: publicKey)
        if let ownedUserProfile = realm.object(ofType: ROwnedUserProfile.self, forPrimaryKey: publicKey) {
            realm.writeAsync {
                ownedUserProfile.selected = true
            }
        } else {
            let ownedUserProfile = ROwnedUserProfile.create(withPublicKey: publicKey)
            ownedUserProfile.selected = true
            realm.writeAsync {
                self.realm.add(ownedUserProfile)
            }
        }
    }

}
