//
//  WebSocketTest.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/31/20.
//

import UIKit
import Network

class WebSocketTest: UIViewController{
    
    override func viewDidLoad() {
        self.view.backgroundColor = .blue
        testWebSocket()
    }
    
    func testWebSocket(){
        let bridgeIP = "192.168.1.175"
        let bridgeUser = "0ZaZRrSyiEoQYiw05AKrHmKsOuIcpcu1W8mb0Qox"
        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/") else {return}
        let task = URLSession.shared.webSocketTask(with: url)
        task.resume()
        
        
        
//        let parameters = NWParameters.tls
//        let websocketOptions = NWProtocolWebSocket.Options()
//        parameters.defaultProtocolStack.applicationProtocols.insert(websocketOptions, at: 0)
//        let websocketConnection = NWConnection(to: , using: parameters)
    }
}
