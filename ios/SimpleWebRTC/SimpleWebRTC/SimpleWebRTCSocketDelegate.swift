//
//  SimpleWebRTCSocketDelegate.swift
//  SimpleWebRTCDemo
//
//  Created by Dylan Sturgeon on 12/21/14.
//  Copyright (c) 2014 RealBotics Inc. All rights reserved.
//

import Foundation

class SimpleWebRTCSocketDelegate : WebSocketDelegate{
    private var rtcDelegate : SimpleWebRTCDelegate!
    
    init(delegate : SimpleWebRTCDelegate){
        rtcDelegate = delegate
    }
    
    
    func handleIncomingMessage(socket: WebSocket, messageType: String, data: NSDictionary?) {
        println("Received message: \(messageType)")
        
        switch messageType {
        case "roomConnected":
            roomConnected(data)
        case "peerConnected":
            peerJoinedRoom(data, socket: socket)
        case "RTCSessionDescription":
            sessionDescriptionReceived(data)
            
        case "RTCICECandidate":
            iceCandidateReceived(data)
            
        case "iceServerConfig":
            iceServerConfigurationReceived(data)
            
        default:
            println("Unexpected message \(messageType) received")
            
        }
        
    }
    
    private func sessionDescriptionReceived(data : NSDictionary?){
        if data == nil {
            return
        }
        
        let sdp : NSDictionary = data!.valueForKey("sdp") as NSDictionary
        let type = sdp.valueForKey("type") as String
        let description = sdp.valueForKey("description") as String
        
        let remoteSession = RTCSessionDescription(type: type, sdp: description)
        rtcDelegate.handleIncomingRemoteSDP(remoteSession)
    }
    
    private func roomConnected(data : NSDictionary?){
        rtcDelegate.roomConnected(data)
    }
    
    private func peerJoinedRoom(data : NSDictionary?, socket : WebSocket){
        if data == nil {
            return
        }
        
        var initiator = data!.valueForKey("isInitiator") as Bool
        rtcDelegate.peerConnected(initiator)
        
        socket.emit("getICEServers", data: nil)
    }
    
    private func iceCandidateReceived(data : NSDictionary?){
        if data == nil {
            return
        }
        
        let candidate = data!.valueForKey("candidate") as NSDictionary
        let candidateSdp = candidate.valueForKey("sdp") as String
        let candidateMid = candidate.valueForKey("sdpMid") as String
        let candidateIndex = candidate.valueForKey("sdpMLineIndex") as Int
        
        var remoteCandidate = RTCICECandidate(mid: candidateMid, index: candidateIndex, sdp: candidateSdp)
        rtcDelegate.handleIncomingRemoteCandidate(remoteCandidate)
    }
    
    private func iceServerConfigurationReceived(data : NSDictionary?){
        if data == nil {
            return
        }
        var response = data!.valueForKey("iceServers") as NSDictionary
        var servers = response.valueForKey("servers") as [NSDictionary]
        var iceServers : [RTCICEServer] = []
        
        for serverCandidate in servers {
            var url = serverCandidate.valueForKey("url") as String
            var user = serverCandidate.valueForKey("username") as String?
            var credential = serverCandidate.valueForKey("credential") as String?
            
            var server = RTCICEServer(URI: NSURL(string: url)!, username: user, password: credential)
            iceServers.append(server)
        }
        
        println("Server count: \(iceServers.count)")
        rtcDelegate.receivedICEServerConfig(iceServers)
    }
    
    
}