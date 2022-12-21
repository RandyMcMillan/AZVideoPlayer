//
//  ImportKeyView.swift
//  Seer
//
//  Created by Jacob Davis on 12/19/22.
//

import SwiftUI
import NostrKit

struct ImportKeyView: View {
    
    @State private var keytext = ""
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
    
        NavigationStack {
            List {
                TextEditor(text: $keytext)
                    .scrollContentBackground(.hidden)
                    .frame(height: 100)
            }
            .listStyle(.grouped)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Import Private Key")
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    if trySavePrivateKey() {
                        dismiss()
                    }
                }, label: {
                    Text("Import")
                        .frame(maxWidth: .infinity, maxHeight: 40)
                })
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
    
    func trySavePrivateKey() -> Bool {
        if keytext.hasPrefix("nsec"), let keypair = try? KeyPair(bech32PrivateKey: keytext) {
            NostrData.shared.save(privateKey: keypair.privateKey, forPublicKey: keypair.publicKey)
            return true
        } else if let keypair = try? KeyPair(privateKey: keytext)  {
            NostrData.shared.save(privateKey: keypair.privateKey, forPublicKey: keypair.publicKey)
            return true
        }
        return false
    }
}

struct ImportKeyView_Previews: PreviewProvider {
    static var previews: some View {
        ImportKeyView()
    }
}
