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
    let config: Config
    let schedules: [String: Schedules]
    let scenes: [String: Scenes]
    let resourcelinks: [String: Resourcelinks]
    let rules: [String: Rules]
    let sensors: [String: Sensor]
    //MARK: - Light
    struct Light: Codable{
        let state : State
        let type: String
        let name: String
        let modelid : String
        let manufacturername : String
        let productname : String
        let capabilities : Capabilities
        let config : LightConfig
        let uniqueid : String
        let swversion : String
        let swconfigid : String
        let productid : String
    }
    //MARK: - Light - State
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
    //MARK: - Light - Capabilities
    struct Capabilities: Codable{
        let certified : Bool
        let control: Control
        let streaming : Streaming
    }
    //MARK: - Light - Control
    struct Control: Codable{
        let mindimlevel : Int
        let maxlumen : Int
    }
    //MARK: - Light - Streaming
    struct Streaming : Codable{
        let renderer: Bool
        let proxy : Bool
    }
    //MARK: - Light - Config
    struct LightConfig: Codable{
        let archetype : String
        let function : String
        let direction : String
        let startup: Startup
    }
    //MARK: - Light - Startup
    struct Startup: Codable{
        let mode : String
        let configured : Bool
    }
    
    //MARK: - Groups
    struct Groups: Codable{
        
        enum CodingKeys: String, CodingKey{
            case name, lights, sensors, type, state, recycle, action, stream, locations
            case groupClass = "class"
        }
        //let id : String! // TODO: Consider writing a custom decoder instead of having this:
        let name: String
        let lights: [String]
        let sensors: [String] // I don't have any sensors, so it's blank in the json, not sure what it is by default
        let type: String
        let state: GroupState
        let recycle: Bool
        let groupClass : String
        let action: GroupAction
        let stream: Stream?
        let locations: [String: [Double]]?
    }
    
    //MARK: - Group State
    struct GroupState: Codable{
        let all_on: Bool
        let any_on: Bool
    }
    //MARK: - Group Action
    struct GroupAction: Codable{
        //All lights in group
        let on : Bool
        let bri: Int?
        let alert : String?
        //Color lights
        let hue: Int?
        let sat: Int?
        let effect: String?
        let xy: [Double]?
        let ct: Int?
        let colormode : String?
    }
    //MARK: - Groups - Stream
    struct Stream: Codable {
        let proxymode: String
        let proxynode: String
        let active: Bool
        let owner: String?
    }
    //MARK: - Groups - Locations
//    struct Locations: Codable{
//
//    }
    
    
    //MARK: - Config
    struct Config: Codable{
        let name: String
        let zigbeechannel: Int
        let bridgeid: String
        let mac: String
        let dhcp: Bool
        let ipaddress: String
        let netmask: String
        let gateway: String
        let proxyaddress: String
        let proxyport: Int
        let UTC: String
        let localtime: String
        let timezone: String
        let modelid: String
        let datastoreversion: String
        let swversion: String
        let apiversion: String
        let linkbutton: Bool
        let portalservices: Bool
        let portalconnection: String
        let portalstate: Portalstate
        let internetservices: Internetservices
        let factorynew: Bool?
        let whitelist: [String:Whitelist]
    }
    //MARK: - Config - Portalstate
    struct Portalstate: Codable{
        let signedon: Bool
        let incoming: Bool
        let outgoing: Bool
        let communication: String
    }
    //MARK: - Config - Internetservices
    struct Internetservices: Codable {
        let internet: String
        let remoteaccess: String
        let time: String
        let swupdate: String
    }
    //MARK: - Config - Whitelist
    struct Whitelist: Codable{
        let name: String
    }
    
    
    //MARK: - Config - Swupdate2 - Bridge
    struct Bridge: Codable {
        let state: String
        let lastinstall: String
    }
    
    
    //MARK: - Schedules
    struct Schedules: Codable{
        let name: String
        let description: String
        let command: Command
        let localtime: String
        let time: String
        let created: String
        let status: String
        let starttime: String
        let recycle: Bool
    }
    //MARK: - Schedule - Command
    struct Command: Codable{
        let address: String
        let body : Body
        let method: String
    }
    
    //MARK: - Schedule - Body
    struct Body: Codable{
        let scene: String?
        let status: Int?
    }
    
    //MARK: - Scenes
    struct Scenes: Codable{
        let name: String
        let type: String
        let group: String?
        let lights: [String]
        let owner: String
        let recycle: Bool
        let locked: Bool
        let appdata: Appdata?
        let picture: String?
        let image: String?
        let lastupdated: String
        let version: Int
        let lightstates: [String: Lightstates]?
    }
    //MARK: - Scenese - AppData
    struct Appdata: Codable{
        let version: Int?
        let data: String?
    }
    //MARK: - Scenes - Lightstates
    struct Lightstates: Codable{
        var on: Bool
        var bri: Int
        var xy: [Double]?
    }
    
    
    //MARK: - Resourcelinks
    struct Resourcelinks: Codable{
        let name: String
        let description: String
        let type: String
        let classid: Int
        let owner: String
        let recycle: Bool
        let links: [String]
    }
    //MARK: - Rules
    struct Rules: Codable{
        let name: String
        let owner: String
        let created: String
        let lastTriggered: String?
        let timestriggered: Int
        let status: String
        let recycle: Bool
        let conditions: [Conditiions]
        let actions: [Actions]
    }
    
    //MARK: - Rules - Conditiions
    struct Conditiions: Codable{
        enum CodingKeys: String, CodingKey{
            case address, value
            case mathOperator = "operator"
        }
        let address: String
        let mathOperator: String
        let value: String?
        
    }
    //MARK: - Rules - Actions
    struct Actions: Codable{
        let address: String
        let method: String
        let body: RulesBody
    }
    
    //MARK: - Rules - Actions - RulesBody
    struct RulesBody: Codable {
        let storelightstate: Bool?
        let scene: String?
    }
    
    //MARK: - Sensors
    struct Sensor: Codable{
        let state: SensorState
        let config: SensorConfig
        let name: String
        let type: String
        let modelid: String
        let manufacturername: String
        let swversion: String
        let uniqueid: String?
        let recycle: Bool?
    }
    //MARK: - Sensors - SensorState
    struct SensorState: Codable{
        let status: Int?
        let daylight: Bool?
        let lastupdated: String
    }
    
    //MARK: - Sensors - SensorConfig
    struct SensorConfig: Codable {
        let on: Bool
        let configured: Bool?
        let sunriseoffset: Double?
        let sunsetoffset: Double?
        let reachable: Bool?
    }
}
