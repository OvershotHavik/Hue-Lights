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
    }
    struct ErrorFromBridge: Codable {
        let description : String
    }
}
