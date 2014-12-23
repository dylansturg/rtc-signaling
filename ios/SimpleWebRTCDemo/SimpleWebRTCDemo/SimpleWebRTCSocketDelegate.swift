//
//  SimpleWebRTCSocketDelegate.swift
//  SimpleWebRTCDemo
//
//  Created by Dylan Sturgeon on 12/21/14.
//  Copyright (c) 2014 RealBotics Inc. All rights reserved.
//

import Foundation

class SimpleWebRTCSocketDelegate : WebSocketDelegate{
    func handleIncomingMessage(socket: WebSocket, messageType: String, data: NSDictionary?) {
            println("Received message: \(messageType)")
    }
    
    private func sessionDescriptionReceived(data : NSDictionary?){
        
    }
    
    private func roomConnected(data : NSDictionary?){
        
    }
    
    private func peerJoinedRoom(data : NSDictionary?, socket : WebSocket){
        
    }
    
    private func iceCandidateReceived(data : NSDictionary?){
        
    }
    
    private func iceServerConfigurationReceived(data : NSDictionary?){
        
    }
    
    
}