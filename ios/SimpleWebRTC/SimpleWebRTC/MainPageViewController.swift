//
//  MainPageViewController.swift
//  SimpleWebRTCDemo
//
//  Created by Dylan Sturgeon on 12/20/14.
//  Copyright (c) 2014 RealBotics Inc. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class MainPageViewController : UIViewController, SimpleWebRTCStreamDelegate, RTCEAGLVideoViewDelegate {
    
    private var videoView : RTCEAGLVideoView?
    private var remoteVideoTrack : RTCVideoTrack?
    
    private var rtcDelegate : SimpleWebRTCDelegate?
    private var signalingDelegate : SimpleWebRTCSocketDelegate?
    private var signalingSocket : WebSocket?
    
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var roomIdField: UITextField!
    
    
    @IBAction func connectTapped(sender: AnyObject) {
        var roomId = roomIdField.text
        if countElements(roomId) <= 0{
            println("RoomId must be a non-null string")
            return
        }
        
        rtcDelegate = SimpleWebRTCDelegate(delegate: self)
        signalingDelegate = SimpleWebRTCSocketDelegate(delegate: rtcDelegate!)
        signalingSocket = WebSocket(delegate: signalingDelegate!, room: roomId)
        
    }
    
    
    override func viewDidLoad() {
        
    }
    
    override func viewDidAppear(animated: Bool) {
        videoView = RTCEAGLVideoView(frame: videoContainer.bounds)
        videoView?.delegate = self
        videoContainer.addSubview(videoView!)
    }
    
    override func viewDidDisappear(animated: Bool) {
    
    }
    
    func addVideoStream(track : RTCVideoTrack){
        remoteVideoTrack = track
        remoteVideoTrack?.addRenderer(videoView!)

    }
    
    // ---- RTCEAGLEVideoViewDelegate ----
    func videoView(videoView: RTCEAGLVideoView!, didChangeVideoSize size: CGSize) {
        videoView?.frame = AVMakeRectWithAspectRatioInsideRect(size, videoContainer.bounds)
    }
}