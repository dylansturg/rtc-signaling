//
//  WebSocket.swift
//  SimpleWebRTCDemo
//
//  Created by Dylan Sturgeon on 12/20/14.
//  Copyright (c) 2014 RealBotics Inc. All rights reserved.
//

import Foundation
import UIKit

class WebSocket : NSObject {
    private let server = "http://137.112.154.199:3000"
    private var signalingSocket : SIOSocket?
    private var roomId : String!
    private var delegate : WebSocketDelegate!

    init(delegate : WebSocketDelegate, room : String){
        super.init()
        
        self.delegate = delegate
        roomId = room
        
        SIOSocket.socketWithHost(server, response: {
            (socket : SIOSocket!) in
                self.signalingSocket = socket
                self.connect()
        })
    }
    
    deinit{
        
    }
    
    func connect(){
        signalingSocket?.emit("joinRoom", args: [["roomId":self.roomId]])
        
        signalingSocket?.on("roomConnected", callback: {
            (data : [AnyObject]!) in
            println("Connected to room")
            self.delegate.handleIncomingMessage(self, messageType: "roomConnected", data: data[0] as? NSDictionary)
        })
        
        signalingSocket?.on("peerConnected", callback: {
            (data : [AnyObject]!) in
            println("Peer joined room")
            self.delegate.handleIncomingMessage(self, messageType: "peerConnected", data: data[0] as? NSDictionary)
        })
        
        signalingSocket?.on("RTCSessionDescription", callback: {
            (data : [AnyObject]!) in
            println("Received remote SDP")
            self.delegate.handleIncomingMessage(self, messageType: "RTCSessionDescription", data: data[0] as? NSDictionary)
        })
        
        signalingSocket?.on("RTCICECandidate", callback: {
            (data : [AnyObject]!) in
            println("Received remote candidate")
            self.delegate.handleIncomingMessage(self, messageType: "RTCICECandidate", data: data[0] as? NSDictionary)
        })
        
        signalingSocket?.on("iceServerConfig", callback: {
            (data : [AnyObject]!) in
            println("Received config for ICE Servers")
            self.delegate.handleIncomingMessage(self, messageType: "iceServerConfig", data: data[0] as? NSDictionary)
        })
    }
    
    
    func emit(message : String, data : NSDictionary?){        
        signalingSocket?.emit(message, args: NSArray(object: data ?? NSDictionary()))
    }
}