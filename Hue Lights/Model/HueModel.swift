//
//  HueModel.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/18/20.
//

import Foundation

struct HueModel: Codable{
    let lights :  [String:Light]

    struct Light: Codable{
        let state : State
        let type: String
        let name: String
        let modelid : String
        let manufacturername : String
        let productname : String
        let capabilities : Capabilities
        let config : Config
        let uniqueid : String
        let swversion : String
        let swconfigid : String
        let productid : String
    }
    
    struct State: Codable{
        let on : Bool
        let bri: Int
        let alert : String
        let mode: String
        let reachable: Bool
    }
    
    struct Capabilities: Codable{
        let certified : Bool
        let control: Control
        let streaming : Streaming
    }
    struct Control: Codable{
        let mindimlevel : Int
        let maxlumen : Int
    }
    struct Streaming : Codable{
        let renderer: Bool
        let proxy : Bool
    }
    struct Config: Codable{
        let archetype : String
        let function : String
        let direction : String
        let startup: Startup
    }
    struct Startup: Codable{
        let mode : String
        let configured : Bool
    }
 
}
