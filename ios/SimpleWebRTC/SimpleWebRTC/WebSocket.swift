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
    private let server = "http://54.69.9.205:3000/"
    private var signalingSocket : SIOSocket?
    private var incomingSocket : SIOSocket?
    private var roomId : String!
    private var delegate : WebSocketDelegate!

    init(delegate : WebSocketDelegate, room : String){
        super.init()
        
        self.delegate = delegate
        roomId = room
        
        SIOSocket.socketWithHost("\(server)user_com", response: {
            (socket : SIOSocket!) in
                self.signalingSocket = socket
                self.connect()
        })
        
        SIOSocket.socketWithHost("\(server)device_com", response: {
            (socket : SIOSocket!) in
                self.incomingSocket = socket
                self.connect()
        })
    }
    
    deinit{
        
    }
    
    func connect(){
        if(signalingSocket == nil || incomingSocket == nil){
            return;
        }
        
        signalingSocket?.emit("join_room", args: [["deviceID":self.roomId, "type":1]])
        signalingSocket?.emit("refresh")
        
        signalingSocket?.on("not_inline", callback: {
            (data : [AnyObject]!) in
            //self.signalingSocket?.emit("getinline")
        })
        
        incomingSocket?.on("receiveVideoOffer", callback: {
            (data : [AnyObject]!) in
            println("Received remote SDP")
            self.delegate.handleIncomingMessage(self, messageType: "RTCSessionDescription", data: data[0] as? NSDictionary)
        })
        
        incomingSocket?.on("receiveICECandidate", callback: {
            (data : [AnyObject]!) in
            println("Received remote candidate")
            self.delegate.handleIncomingMessage(self, messageType: "RTCICECandidate", data: data[0] as? NSDictionary)
        })
        
        signalingSocket?.on("ICEConfig", callback: {
            (data : [AnyObject]!) in
            println("Received config for ICE Servers")
            self.delegate.handleIncomingMessage(self, messageType: "iceServerConfig", data: data[0] as? NSDictionary)
        })
    }
    
    
    func emit(message : String, data : NSDictionary?){        
        signalingSocket?.emit(message, args: NSArray(object: data ?? NSDictionary()))
    }
}