//
//  CreateUserOnBridge.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 1/2/21.
//

import Foundation
struct CreateUserOnBridge: Codable{
    let success : Success?
    let error: ErrorFromBridge?
    struct Success: Codable{
        let username : String
        let clientkey : String
    }
    struct ErrorFromBridge: Codable {
        let description : String
    }
}

enum BridgeUser: String{
    case username = "username"
    case clientKey = "clientkey"
}
