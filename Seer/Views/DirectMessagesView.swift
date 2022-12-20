//
//  DirectMessagesView.swift
//  Seer
//
//  Created by Jacob Davis on 12/16/22.
//

import SwiftUI
import NostrKit
import RealmSwift
import SDWebImageSwiftUI

struct DirectMessagesView: View {
    
    @EnvironmentObject var nostrData: NostrData
    @EnvironmentObject var navigation: Navigation

    @State private var searchText = ""
    
    @State private var scrollChange: Int = 0
    @State private var viewIsVisible = true
    let homeTapped = NotificationCenter.default.publisher(for: NSNotification.Name("HomeTapped"))
    
    var body: some View {
        ScrollViewReader { reader in
            List {
                ForEach(nostrData.contactedUserProfiles) { userProfile in
                    DirectMessageListViewRow(userProfile: userProfile)
                        .id(userProfile.publicKey)
                }
            }
            .listStyle(.grouped)
            .navigationDestination(for: Navigation.NavUserProfile.self) { nav in
                ProfileDetailView(userProfile: nav.userProfile)
            }
            .navigationDestination(for: Navigation.NavFollowing.self) { nav in
                FollowingView(userProfile: nav.userProfile)
            }
            .navigationDestination(for: Navigation.NavFollowers.self) { nav in
                FollowersView(userProfile: nav.userProfile)
            }
            .navigationDestination(for: Navigation.NavDirectMessage.self) { nav in
                DirectMessageView(userProfile: nav.userProfile)
            }
            .onReceive(homeTapped) { (output) in
                if !navigation.homePath.isEmpty {
                    navigation.homePath.removeLast()
                } else {
                    NostrData.shared.updateLastSeenDate()
                }
                scrollChange += 1
            }
            .onChange(of: scrollChange) { value in
                if viewIsVisible {
                    withAnimation {
                        reader.scrollTo(nostrData.contactedUserProfiles.first?.id, anchor: .top)
                    }
                }
            }
            .onDisappear {
                viewIsVisible = false
            }
            .onAppear {
                viewIsVisible = true
            }
        }
    }
}

struct DirectMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        DirectMessagesView()
    }
}

struct DirectMessageListViewRow: View {
    
    @ObservedRealmObject var userProfile: RUserProfile
    @EnvironmentObject var navigation: Navigation
    
    var body: some View {
        HStack (alignment: .top, spacing: 12) {
            AnimatedImage(url: userProfile.avatarUrl)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .background(
                    Image(systemName: "person.crop.circle.fill").foregroundColor(.secondary).font(.system(size: 48))
                )
                .frame(width: 48, height: 48)
                .cornerRadius(24)
                .onTapGesture {
                    self.navigation.homePath.append(Navigation.NavUserProfile(userProfile: userProfile))
                }

            VStack (alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if let name = userProfile.name, name.isValidName()  {
                        Text(name)
                            .font(.system(.subheadline, weight: .bold))
                    }
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: "key.fill")
                            .imageScale(.small)
                        Text(userProfile.bech32PublicKey.prefix(12))
                    }
                    .font(.system(.caption, weight: .bold))
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    Text((userProfile.getLatestMessage()?.createdAt ?? .now), style: .offset)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                Text(userProfile.getLatestMessage()?.decryptedContent() ?? "Not sure?")
                    .font(.callout)
                    .lineLimit(2)
                    .foregroundColor(.secondary)

            }
            .onTapGesture {
                self.navigation.homePath.append(Navigation.NavDirectMessage(userProfile: userProfile))
            }

        }
    }
}
