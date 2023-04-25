//
//  ContentView.swift
//  osx
//
//  Created by 中山慶 on 2023/04/23.
//

import SwiftUI
import Foundation
import MultipeerConnectivity




struct ContentView: View {
    @StateObject private var mutipeerSession = MultipeerSession()
    @State private var path: [String] = []
    @State private var text = ""
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                List(mutipeerSession.connectedPeers, id: \.self) { peer in
                    Text(peer.displayName)
                }
                HStack {
                    TextEditor(text: $text)
                    Button("Send") {
                        if let data = "Hello".data(using: .utf8) {
                            mutipeerSession.sendData(data, toPeers: mutipeerSession.connectedPeers)
                        }
                        
                    }
                }
            }
            
            
        }.onAppear {
            
        }
        .onDisappear() {
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


class MultipeerSession: NSObject, MCSessionDelegate, ObservableObject {
    private let myPeerID: MCPeerID
    private let serviceType: String = "my-service"
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    @Published var connectedPeers: [MCPeerID] = []
    
    override init() {
        myPeerID = MCPeerID(displayName: Host.className())
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: "my-service")
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: "my-service")
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
         DispatchQueue.main.async { [weak self] in
             guard let self = self else { return }

             switch state {
             case .connected:
                 self.connectedPeers.append(peerID)
             case .notConnected:
                 self.connectedPeers.removeAll { $0 == peerID }
             case .connecting:
                 break
             @unknown default:
                 fatalError("Unknown state received: \(state)")
             }
         }
     }

     func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
         DispatchQueue.main.async { [weak self] in
             guard let self = self else { return }
             
             if let message = String(data: data, encoding: .utf8) {
                 print("Received message from \(peerID.displayName): \(message)")
             }
         }
     }

     func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
         // Not used in this example
     }

     func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
         // Not used in this example
     }

     func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
         // Not used in this example
     }
    

    
    func sendData(_ data: Data, toPeers peers:[MCPeerID]) {
        guard !peers.isEmpty else { return }
        
        do {
            try session.send(data, toPeers: peers, with: .reliable)
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Automatically accept incoming invitatios
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Error advertising: \(error.localizedDescription)")
    }
}

// MARK: - MCNearbyServieBrowserDelegate
extension MultipeerSession: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // Handle lost peer
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Error browsing: \(error.localizedDescription)")
    }
    
    
}
