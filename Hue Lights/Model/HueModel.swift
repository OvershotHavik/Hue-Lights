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
    struct Light: Codable, Equatable{
        static func == (lhs: HueModel.Light, rhs: HueModel.Light) -> Bool {
            return lhs.name == rhs.name && lhs.id == rhs.id
        }
        
        
        enum CodingKeys: String, CodingKey{
            case state, type, name, modelid, manufacturername, productname, capabilities, config, uniqueid, swversion, swconfigid, productid
        }
        let id : String
        var state : State
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
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = container.codingPath.first!.stringValue
            state = try container.decode(State.self, forKey: .state)
            type = try container.decode(String.self, forKey: .type)
            name = try container.decode(String.self, forKey: .name)
            modelid = try container.decode(String.self, forKey: .modelid)
            manufacturername = try container.decode(String.self, forKey: .manufacturername)
            productname = try container.decode(String.self, forKey: .productname)
            capabilities = try container.decode(Capabilities.self, forKey: .capabilities)
            config = try container.decode(LightConfig.self, forKey: .config)
            uniqueid = try container.decode(String.self, forKey: .uniqueid)
            swversion = try container.decode(String.self, forKey: .swversion)
            swconfigid = try container.decode(String.self, forKey: .swconfigid)
            productid = try container.decode(String.self, forKey: .productid)
        }
    }

    //MARK: - Light - State
    struct State: Codable{
        var on : Bool
        var bri: Int
        var hue : Int?
        var sat: Int?
        var effect: String?
        var xy: [Double]?
        var ct : Int?
        var alert : String
        var mode: String
        var reachable: Bool
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
        let configured : Bool?
    }
    
    //MARK: - Groups
    struct Groups: Codable, Equatable{
        static func == (lhs: HueModel.Groups, rhs: HueModel.Groups) -> Bool {
            return lhs.name == rhs.name && lhs.id == rhs.id
        }
        
        enum CodingKeys: String, CodingKey{
            case name, lights, sensors, type, state, recycle, action, stream, locations
            case groupClass = "class"
        }
        let id : String
        var name: String
        var lights: [String]
        let sensors: [String] // I don't have any sensors, so it's blank in the json, not sure what it is by default
        let type: String
        let state: GroupState
        let recycle: Bool
        let groupClass : String
        let action: GroupAction
        let stream: Stream?
        let locations: [String: [Double]]?
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = container.codingPath.first!.stringValue
            name = try container.decode(String.self, forKey: .name)
            lights = try container.decode([String].self, forKey: .lights)
            sensors = try container.decode([String].self, forKey: .sensors)
            type = try container.decode(String.self, forKey: .type)
            state = try container.decode(GroupState.self, forKey: .state)
            recycle = try container.decode(Bool.self, forKey: .recycle)
            groupClass = try container.decode(String.self, forKey: .groupClass)
            action = try container.decode(GroupAction.self, forKey: .action)
            stream = try container.decodeIfPresent(Stream.self, forKey: .stream)
            locations = try container.decodeIfPresent([String:[Double]].self, forKey: .locations)
        }
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
        enum CodingKeys: String, CodingKey{
            case name, description, command, localtime, time, created, status, starttime, recycle
        }
        let id : String
        let name: String
        let description: String
        let command: Command
        let localtime: String
        let time: String
        let created: String
        let status: String
        let starttime: String
        let recycle: Bool
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = container.codingPath.first!.stringValue
            name = try container.decode(String.self, forKey: .name)
            description = try container.decode(String.self, forKey: .description)
            command = try container.decode(Command.self, forKey: .command)
            localtime = try container.decode(String.self, forKey: .localtime)
            time = try container.decode(String.self, forKey: .time)
            created = try container.decode(String.self, forKey: .created)
            status = try container.decode(String.self, forKey: .status)
            starttime = try container.decode(String.self, forKey: .starttime)
            recycle = try container.decode(Bool.self, forKey: .recycle)
        }
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
        enum CodingKeys: String, CodingKey{
            case name, type, group, lights, owner, recycle, locked, appdata, picture, image, lastupdated, version, lightstates
        }
        var id : String
        var name: String
        var type: String
        var group: String?
        var lights: [String]
        var owner: String
        var recycle: Bool
        var locked: Bool
        var appdata: Appdata?
        var picture: String?
        var image: String?
        var lastupdated: String
        var version: Int
        var lightstates: [String: Lightstates]?
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = container.codingPath.first!.stringValue
            name = try container.decode(String.self, forKey: .name)
            type = try container.decode(String.self, forKey: .type)
            group = try container.decodeIfPresent(String.self, forKey: .group)
            lights = try container.decode([String].self, forKey: .lights)
            owner = try container.decode(String.self, forKey: .owner)
            recycle = try container.decode(Bool.self, forKey: .recycle)
            locked = try container.decode(Bool.self, forKey: .locked)
            appdata = try container.decodeIfPresent(Appdata.self, forKey: .appdata)
            picture = try container.decodeIfPresent(String.self, forKey: .picture)
            image = try container.decodeIfPresent(String.self, forKey: .image)
            lastupdated = try container.decode(String.self, forKey: .lastupdated)
            version = try container.decode(Int.self, forKey: .version)
            lightstates = try container.decodeIfPresent([String:Lightstates].self, forKey: .lightstates)
        }
    }
    struct IndividualScene: Codable{ // When getting the lightStates, you have to pull the scene individually, and it does not have an ID at that level
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
