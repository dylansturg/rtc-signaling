//
//  SimpleWebRTCDelegate.swift
//  SimpleWebRTCDemo
//
//  Created by Dylan Sturgeon on 12/21/14.
//  Copyright (c) 2014 RealBotics Inc. All rights reserved.
//

import Foundation

class SimpleWebRTCDelegate : NSObject, RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate{
    private var constraints = RTCMediaConstraints(mandatoryConstraints: [RTCPair(key: "offerToReceiveAudio", value: "true"), RTCPair(key: "offerToReceiveVideo", value: "true")], optionalConstraints: [RTCPair(key: "DtlsSrtpKeyAgreement", value: "true")])
    
    private var isInitiator : Bool = false
    private var hasSentAnswer : Bool = false
    private var candidateQueue : [RTCICECandidate]? = []
    private var streamDelegate : SimpleWebRTCStreamDelegate
    private var peerConnection : RTCPeerConnection?
    
    private var serverConfig : [RTCICEServer]?
    private var remoteSDP : RTCSessionDescription?
    
    private var signalingSocket : WebSocket?
    
    private struct Factory {
        static var peerConnectionFactory = RTCPeerConnectionFactory()
    }
    
    
    init(delegate : SimpleWebRTCStreamDelegate){
        streamDelegate = delegate
    }
    
    func roomConnected(data : NSDictionary?, socket : WebSocket){
        println("Successfully joined room")
    }
    
    func peerConnected(isInitiator : Bool, socket : WebSocket){
        self.isInitiator = isInitiator
        socket.emit("getICEServers", data: nil)
    }
    
    func handleIncomingRemoteSDP(sdp : RTCSessionDescription, socket : WebSocket){
        remoteSDP = sdp
        sendAnswerIfReady()
    }
    
    func handleIncomingRemoteCandidate(candidate : RTCICECandidate, socket : WebSocket){
        if candidateQueue == nil{
            peerConnection?.addICECandidate(candidate)
        } else {
            candidateQueue?.append(candidate)
        }
    }
    
    func receivedICEServerConfig(servers : [RTCICEServer], socket : WebSocket){
        signalingSocket = socket
        serverConfig = servers
        if isInitiator{
            createAndSendVideoOffer(servers)
        } else {
            sendAnswerIfReady()
        }
    }
    
    private func createAndSendVideoOffer(iceServerConfig : [RTCICEServer]){
        if !isInitiator {
            // Only the initiator sends an offer
            return;
        }
        createLocalPeerConnection(iceServerConfig)
        peerConnection?.createOfferWithDelegate(self, constraints: self.constraints)
    }
    
    private func sendAnswerIfReady(){
        if serverConfig != nil && remoteSDP != nil{
            if isInitiator{
                peerConnection?.setRemoteDescriptionWithDelegate(self, sessionDescription: remoteSDP)
            } else {
                // need to create and send an answer
                createLocalPeerConnection(serverConfig!)
                peerConnection?.setRemoteDescriptionWithDelegate(self, sessionDescription: remoteSDP)
            }
        }
    }
    
    private func forwardCandidateQueue(){
        if candidateQueue != nil {
            for remoteCandidate in candidateQueue! {
                peerConnection?.addICECandidate(remoteCandidate)
            }
        }
    }
    
    private func sendLocalCandidate(candidate : RTCICECandidate, socket : WebSocket){
        var candidateData = NSMutableDictionary()
        candidateData["candidate"] = candidate.sdp
        candidateData["sdpMid"] = candidate.sdpMid
        candidateData["sdpMLineIndex"] = candidate.sdpMLineIndex
        
        socket.emit("forwardRTCICECandidate", data: ["candidate": candidateData])
    }
    
    private func  sendLocalSessionDescription(sdp : RTCSessionDescription, socket : WebSocket){
        var offerData = NSMutableDictionary()
        offerData["sdp"] = sdp.description
        offerData["type"] = sdp.type
        
        var serializedOffer = NSJSONSerialization.dataWithJSONObject(offerData, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
        var offerString = NSString(data: serializedOffer!, encoding: NSUTF8StringEncoding)
        
        socket.emit("forwardRTCSDP", data: ["sdp": offerData])
    }
    
    private func createLocalPeerConnection(iceServerConfig : [RTCICEServer]){
        peerConnection = Factory.peerConnectionFactory.peerConnectionWithICEServers(iceServerConfig, constraints: constraints, delegate: self)
    }
    
    
    // --- RTCSessionDescriptionDelegate ----
    func peerConnection(peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: NSError!) {
        if signalingSocket != nil {
            sendLocalSessionDescription(sdp, socket: signalingSocket!)
            peerConnection.setLocalDescriptionWithDelegate(isInitiator ? nil : self, sessionDescription: sdp)
            if sdp.type == "answer"{
                hasSentAnswer = true
            }
        }
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error: NSError!) {
        if isInitiator{
            forwardCandidateQueue()
        } else if !hasSentAnswer{
            peerConnection.createAnswerWithDelegate(self, constraints: RTCMediaConstraints())
        } else {
            forwardCandidateQueue()
        }
    }
    
    // ---- RTCPeerConnectionDelegate ----
    func peerConnection(peerConnection : RTCPeerConnection!, addedStream stream : RTCMediaStream!){
        streamDelegate.addVideoStream(stream.videoTracks[0] as RTCVideoTrack)
    }
    
    func peerConnection(peerConnection : RTCPeerConnection!, removedStream stream : RTCMediaStream!){
        // TODO: Consider handling if an error condition
    }
    
    func peerConnection(peerConnection : RTCPeerConnection!, didOpenDataChannel dataChannel : RTCDataChannel!){
        // Not using data channel
    }
    
    
    func peerConnection(peerConnection : RTCPeerConnection!, gotICECandidate candidate: RTCICECandidate!){
        println("got an ICE cadidate to forward")
        if signalingSocket != nil {
            sendLocalCandidate(candidate, socket: signalingSocket!)
        }

    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, iceConnectionChanged newState: RTCICEConnectionState) {
        if newState.value == RTCICEConnectionConnected.value{
            println("WebRTC: ICE Connected")
        }
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, iceGatheringChanged newState: RTCICEGatheringState) {
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, signalingStateChanged stateChanged: RTCSignalingState) {
        if stateChanged.value == RTCSignalingStable.value {
            println("WebRTC: Signal Stable")
        }
    }
    
    func peerConnectionOnError(peerConnection: RTCPeerConnection!) {
        println("WebRTC: Connection Error")
    }
    
    func peerConnectionOnRenegotiationNeeded(peerConnection: RTCPeerConnection!) {
        
    }
    
}
