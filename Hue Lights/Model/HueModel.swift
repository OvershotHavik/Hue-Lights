//
//  HueModel.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/18/20.
//

import Foundation

struct HueModel: Codable{
    let lights :  [String:Light]
    let groups: [String: Groups]

    
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
        let hue : Int?
        let sat: Int?
        let effect: String?
        let xy: [Double]?
        let ct : Int?
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
 
    
    
    
    //MARK: - Groups
    struct Groups: Codable{
        let name: String
        let lights: [String]
        let sensors: [String] // I don't have any sensors, so it's blank in the json, not sure what it is by default
        let type: String
        let state: GroupState
        let recycle: Bool
//        let groupClass : String // CK needed - would be used to pick an icon for the group. Not sure if needed, not including right now
        let action: GroupAction
    }
    
    struct GroupState: Codable{
        let all_on: Bool
        let any_on: Bool
    }
    struct GroupAction: Codable{
        //All lights in group
        let on : Bool
        let bri: Int
        let alert : String
        //Color lights
        let hue: Int?
        let sat: Int?
        let effect: String?
        let xy: [Double]?
        let ct: Int?
        let colormode : String?
    }
}
