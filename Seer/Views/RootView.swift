//
//  RootView.swift
//  Seer
//
//  Created by Jacob Davis on 11/4/22.
//

import SwiftUI
import RealmSwift
import NostrKit

struct RootView: View {
    
    @EnvironmentObject var navigation: Navigation
    @EnvironmentObject var nostrData: NostrData
    @State private var selection = 0
    @State private var needsImport = false

    var selectionHandler: Binding<Int> { Binding(
        get: { self.selection },
        set: {
            if $0 == self.selection {
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name("HomeTapped"), object: nil)
            }
            self.selection = $0
        }
    )}
    
    var body: some View {
        NavigationStack(path: $navigation.homePath) {
            TabView(selection: selectionHandler) {
                DirectMessagesView()
                    .toolbarBackground(.visible, for: .tabBar)
                    .tabItem {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                    }
                    .tag(0)
                
                Text("Contacts")
                    .toolbarBackground(.visible, for: .tabBar)
                    .tabItem {
                        Image(systemName: "person.crop.rectangle.stack.fill")
                    }
                    .tag(1)
                
                Text("Settings")
                    .toolbarBackground(.visible, for: .tabBar)
                    .tabItem {
                        Image(systemName: "gearshape")
                    }
                    .tag(3)
            }
            .navigationTitle(getNavigationTitle())
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $needsImport, onDismiss: {
            needsImport = nostrData.selectedUserProfile() == nil
            if needsImport != true {
                nostrData.disconnect()
                nostrData.reconnect()
            }
        }) {
            ImportKeyView()
        }
        .onAppear {
            needsImport = nostrData.selectedUserProfile() == nil
        }
        
    }
    
    func getNavigationTitle() -> String {
        if selection == 0 {
            return "Messages"
        } else if selection == 1 {
            return "Contacts"
        } else {
            return "Settings"
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(NostrData.shared)
    }
}
