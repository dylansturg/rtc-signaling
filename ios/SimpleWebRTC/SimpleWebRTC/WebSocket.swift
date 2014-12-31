//
//  WebSocket.swift
//  SimpleWebRTCDemo
//
//  Created by Dylan Sturgeon on 12/20/14.
//  Copyright (c) 2014 RealBotics Inc. All rights reserved.
//

import Foundation
import UIKit

class WebSocket : UIWebView {

    init(delegate : WebSocketDelegate){
        super.init()
        
        self.delegate = WebSocketWebViewDelegate(socketDelegate: delegate);
        let filePath = NSBundle.mainBundle().pathForResource("WebSocket", ofType: "html")
        let fileHtml : String = NSString(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding, error: nil)!
        
        loadHTMLString(fileHtml, baseURL: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit{
        
    }
    
    func connect(roomId : String){
        stringByEvaluatingJavaScriptFromString("connect(\"\(roomId)\");");
    }
    
    func emit(message : String, data : String?){
        var dataString = data ?? "";
        stringByEvaluatingJavaScriptFromString("emit(\"\(message)\", \"\(dataString)\");")
    }
}

class WebSocketWebViewDelegate : NSObject, UIWebViewDelegate{
    private var delegate : WebSocketDelegate!
    
    init(socketDelegate : WebSocketDelegate){
        delegate = socketDelegate
    }
    
    func webView(webView: UIWebView,
        shouldStartLoadWithRequest request: NSURLRequest,
        navigationType: UIWebViewNavigationType) -> Bool{
            
            if request.URL.scheme == "webrtc" {
                if let del = self.delegate {
                    var messageType = request.URL.host
                    var hasPayload : Bool = request.URL.fragment == "payload"
                    var parsedMessage : NSDictionary? = nil
                    if hasPayload {
                        let payload = webView.stringByEvaluatingJavaScriptFromString("popMessage();")
                        let data = payload!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                        parsedMessage = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary?
                        if(parsedMessage == nil){
                            parsedMessage = NSDictionary(object: payload!, forKey: "message")
                        }
                    }
                    
                    del.handleIncomingMessage(webView as WebSocket, messageType: messageType!, data: parsedMessage)
                    
                }
                return false;
            }
            
            return true;
    }
    
    func webViewDidStartLoad(webView: UIWebView){
        
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        println(error)
    }

}