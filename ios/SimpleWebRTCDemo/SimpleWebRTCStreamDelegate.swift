//
//  SimpleWebRTCStreamDelegate.swift
//  SimpleWebRTCDemo
//
//  Created by Dylan Sturgeon on 12/21/14.
//  Copyright (c) 2014 RealBotics Inc. All rights reserved.
//

import Foundation

protocol SimpleWebRTCStreamDelegate{
    func addVideoStream(track : RTCVideoTrack);
}