//
//  SimpleWebRTCSocketDelegate.swift
//  SimpleWebRTCDemo
//
//  Created by Dylan Sturgeon on 12/21/14.
//  Copyright (c) 2014 RealBotics Inc. All rights reserved.
//

import Foundation

class SimpleWebRTCSocketDelegate : NSObject, WebSocketDelegate{
    private var rtcDelegate : SimpleWebRTCDelegate!
    
    init(delegate : SimpleWebRTCDelegate){
        rtcDelegate = delegate
    }
    
    func handleIncomingMessage(socket: WebSocket, messageType: String, data: NSDictionary?) {
        println("Received message: \(messageType)")
        
        switch messageType {
        case "roomConnected":
            roomConnected(data, socket: socket)
        case "peerConnected":
            peerJoinedRoom(data, socket: socket)
        case "RTCSessionDescription":
            sessionDescriptionReceived(data, socket: socket)
            
        case "RTCICECandidate":
            iceCandidateReceived(data, socket: socket)
            
        case "iceServerConfig":
            iceServerConfigurationReceived(data, socket: socket)
            
        default:
            println("Unexpected message \(messageType) received")
            
        }
        
    }
    
    private func sessionDescriptionReceived(data : NSDictionary?, socket : WebSocket){
        if data == nil {
            return
        }
        
        let sdp : NSDictionary = data!.valueForKey("sdp") as NSDictionary
        let type = sdp.valueForKey("type") as String
        let description = sdp.valueForKey("sdp") as String
        
        let remoteSession = RTCSessionDescription(type: type, sdp: description)
        rtcDelegate.handleIncomingRemoteSDP(remoteSession, socket: socket)
    }
    
    private func roomConnected(data : NSDictionary?, socket : WebSocket){
        rtcDelegate.roomConnected(data, socket: socket)
    }
    
    private func peerJoinedRoom(data : NSDictionary?, socket : WebSocket){
        if data == nil {
            return
        }
        
        var initiator = data!.valueForKey("isInitiator") as Bool
        rtcDelegate.peerConnected(initiator, socket: socket)
        
        socket.emit("getICEServers", data: nil)
    }
    
    private func iceCandidateReceived(data : NSDictionary?, socket : WebSocket){
        if data == nil {
            return
        }
        
        let candidate = data!.valueForKey("candidate") as NSDictionary
        let candidateSdp = candidate.valueForKey("candidate") as String
        let candidateMid = candidate.valueForKey("sdpMid") as String
        let candidateIndex = candidate.valueForKey("sdpMLineIndex") as Int
        
        var remoteCandidate = RTCICECandidate(mid: candidateMid, index: candidateIndex, sdp: candidateSdp)
        rtcDelegate.handleIncomingRemoteCandidate(remoteCandidate, socket: socket)
    }
    
    private func iceServerConfigurationReceived(data : NSDictionary?, socket : WebSocket){
        if data == nil {
            return
        }
        var response = data!.valueForKey("servers") as NSDictionary
        var servers = response.valueForKey("iceServers") as [NSDictionary]
        var iceServers : [RTCICEServer] = []
        
        for serverCandidate in servers {
            var url = serverCandidate.valueForKey("url") as String
            var user = serverCandidate.valueForKey("username") as String?
            var credential = serverCandidate.valueForKey("credential") as String?
            
            var server = RTCICEServer(URI: NSURL(string: url)!, username: user ?? "", password: credential ?? "")
            iceServers.append(server)
        }
        
        println("Server count: \(iceServers.count)")
        rtcDelegate.receivedICEServerConfig(iceServers, socket: socket)
    }
    
    
}