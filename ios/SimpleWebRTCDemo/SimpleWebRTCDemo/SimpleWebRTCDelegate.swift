//
//  SimpleWebRTCDelegate.swift
//  SimpleWebRTCDemo
//
//  Created by Dylan Sturgeon on 12/21/14.
//  Copyright (c) 2014 RealBotics Inc. All rights reserved.
//

import Foundation

class SimpleWebRTCDelegate : NSObject, RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate{
    private var constraints = RTCMediaConstraints(mandatoryConstraints: [RTCPair(key: "DtlsSrtpKeyAgreement", value: "true"), RTCPair(key: "offerToReceiveVideo", value: "true"), RTCPair(key: "offerToReceiveAudio", value: "true")], optionalConstraints: [])
    
    private var isInitiator : Bool = false
    private var hasSentAnswer : Bool = false
    private var candidateQueue : [RTCICECandidate]? = []
    private var socket : WebSocket
    private var streamDelegate : SimpleWebRTCStreamDelegate
    private var peerConnection : RTCPeerConnection?
    
    private var serverConfig : [RTCICEServer]?
    private var remoteSDP : RTCSessionDescription?
    
    init(rtcSocket : WebSocket, delegate : SimpleWebRTCStreamDelegate){
        socket = rtcSocket
        streamDelegate = delegate
    }
    
    func joinRoom(roomId : String){
        socket.emit("joinRoom", data: "{\"roomId\":\"\(roomId)\"}")
    }
    
    func roomConnected(data : NSDictionary?){
        println("Successfully joined room")
    }
    
    func peerConnected(isInitiator : Bool){
        self.isInitiator = isInitiator
        socket.emit("getICEServers", data: nil)
    }
    
    func handleIncomingRemoteCandidate(candidate : RTCICECandidate){
        if candidateQueue == nil{
            peerConnection?.addICECandidate(candidate)
        } else {
            candidateQueue?.append(candidate)
        }
    }
    
    func receivedICEServerConfig(servers : [RTCICEServer]){
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
            sendLocalSessionDescription(remoteSDP!)
        }
    }
    
    private func forwardCandidateQueue(){
        
    }
    
    private func sendLocalCandidate(candidate : RTCICECandidate){
        
    }
    
    private func  sendLocalSessionDescription(sdp : RTCSessionDescription){
        
    }
    
    private func createLocalPeerConnection(iceServerConfig : [RTCICEServer]){
        
    }
    
    
    // --- RTCSessionDescriptionDelegate ----
    func peerConnection(peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: NSError!) {
        if sdp.type == "answer"{
            hasSentAnswer = true
        }
        
        peerConnection.setLocalDescriptionWithDelegate(self, sessionDescription: sdp)
        sendLocalSessionDescription(sdp)
        
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error: NSError!) {
        if isInitiator{
            forwardCandidateQueue()
        } else if !hasSentAnswer{
            peerConnection.createAnswerWithDelegate(self, constraints: self.constraints)
        } else {
            forwardCandidateQueue()
        }
    }
    
    // ---- RTCPeerConnectionDelegate ----
    func peerConnection(peerConnection : RTCPeerConnection!, addedStream stream : RTCMediaStream!){

    }
    
    func peerConnection(peerConnection : RTCPeerConnection!, removedStream stream : RTCMediaStream!){
        // TODO: Consider handling if an error condition
    }
    
    func peerConnection(peerConnection : RTCPeerConnection!, didOpenDataChannel dataChannel : RTCDataChannel!){
        // Not using data channel
    }
    
    
    func peerConnection(peerConnection : RTCPeerConnection!, gotICECandidate candidate: RTCICECandidate!){
        println("got an ICE cadidate to forward")
        var desc = candidate.description
        var candidateDict = NSDictionary(objects: [candidate.description, candidate.sdpMid, candidate.sdpMLineIndex], forKeys: ["candidate", "sdpMid", "sdpMLineIndex"])
        var candidateData = NSJSONSerialization.dataWithJSONObject(candidateDict, options: nil, error: nil) as NSData?
        var candidateJson = NSString(data: candidateData!, encoding: NSUTF8StringEncoding)
        

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
