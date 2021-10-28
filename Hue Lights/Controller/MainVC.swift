//
//  MainVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/15/20.
//

import UIKit

class MainVC: UIViewController {
    fileprivate var rootView : MainView!
    internal var bridgeIP = String()
    fileprivate var clientKey: String?
    fileprivate var appOwner : String?
    fileprivate var baseURL : String?
    fileprivate let defaults = UserDefaults.standard
    fileprivate var discoveredBridges = [Discovery]()
    lazy var selectedBridgeID = self.defaults.object(forKey: Constants.selectedBridge.rawValue) as? String ?? String()
    override func loadView() {
        super.loadView()
        rootView = MainView(selectedBridgeID: selectedBridgeID)
        self.view = rootView
        rootView.getDelegate = self
        rootView.bridgeDelegate = self
//        bridgeKey = "68D5D9EC03F6AD7A73F95D4E148102E1" // Steve's Bridge Key
        discovery()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
//MARK: - Get Delegate
extension MainVC: GetDelegate{
    func getTapped(sender: HueSender) {
        guard let baseURL = baseURL else {
            print("Base url not set in discovery")
            Alert.showBasic(title: "Select a bridge", message: "Please select a bridge", vc: self)
            return
        }
        switch sender {
//MARK: - Lights
        case .lights:
            DataManager.get(baseURL: baseURL, HueSender: .lights) { results in
                switch results{
                case .success(let data):
                    do {
                        let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                        let lights = lightsFromBridge.compactMap{ $0}
                        for light in lights{
                            print("Light id: \(light.id) - \(light.name)")
                        }
                        DispatchQueue.main.async {
                            let lightListVC = LightsListVC(baseURL: baseURL, lightsArray: lights, showingGroup: nil)
                            lightListVC.title = HueSender.lights.rawValue.capitalized
                            self.navigationController?.pushViewController(lightListVC, animated: true)
                        }
                    } catch let e {
                        print("Error getting lights: \(e)")
                    }
                case .failure(let e): print(e)
                }
            }
//MARK: - Groups
        case .groups:
            DataManager.get(baseURL: baseURL,
                            HueSender: .groups) { results in
                switch results{
                case .success(let data):
                    do {
                        let groupsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Groups>.self, from: data)
                        let groups = groupsFromBridge.compactMap{$0}
                        for group in groups{
                            print("Group name: \(group.name), Group id: \(group.id)")
                        }
                        DispatchQueue.main.async {
                            let groupListController = GroupsListVC(baseURL: baseURL, groupsArray: groups)
                            groupListController.title = HueSender.groups.rawValue.capitalized
                            self.navigationController?.pushViewController(groupListController, animated: true)
                        }
                    } catch let e {
                        print("Error getting Groups: \(e)")
                    }

                case .failure(let e): print(e)
                    
                }
            }
//MARK: - Schedules
        case .schedules:
            DataManager.get(baseURL: baseURL,
                            HueSender: .schedules) { results in
                switch results{
                case .success(let data):
                    do {
                        let schedulesFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Schedules>.self, from: data)
                        let schedules = schedulesFromBridge.compactMap {$0}.sorted(by: {$0.name < $1.name})
                        for schedule in schedules{
                            print("Schedule id: \(schedule.id) - \(schedule.name)")
                        }
                        DispatchQueue.main.async {
                            let scheduleList = ScheduleListVC(baseURL: baseURL, appOwner: self.appOwner ?? "", scheduleArray: schedules)
                            scheduleList.title = HueSender.schedules.rawValue.capitalized
                            self.navigationController?.pushViewController(scheduleList, animated: true)
                        }
                    } catch let e {
                        print("Error getting schedules: \(e)")
                    }
                case .failure(let e): print(e)
                }
            }
//MARK: - Light Scenes
        case .lightScenes: ()
            DataManager.get(baseURL: baseURL,
                            HueSender: .scenes) { results in
                switch results{
                case .success(let data):
                    do {
                        let scenesFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Scenes>.self, from: data)
                        let scenes = scenesFromBridge.compactMap {$0}
                        let lightScenes = scenes.filter({$0.type == "LightScene"})
                        let ownedScenes = lightScenes.filter({$0.owner == self.appOwner}) // to display only scenes created by this app
                        for scene in ownedScenes{
                            print("Light Sceen Name: \(scene.name)")
                        }
                        DispatchQueue.main.async {
                            let sceneList = SceneListVC(baseURL: baseURL, group: nil, lightsInScene: [], sceneArray: ownedScenes, appOwner: self.appOwner)
//                            sceneList.delegate = self
                            sceneList.title = HueSender.lightScenes.rawValue.capitalized
                            self.navigationController?.pushViewController(sceneList, animated: true)
                        }
                    } catch let e {
                        print("Error getting scenes: \(e)")
                    }
                case .failure(let e): print(e)
                }
            }
        default:
            print("not setup yet")
        }
    }
}
//MARK: - Discovery
extension MainVC{
    func discovery(){
        //runs at start up. If the bridge IP is different then what is stored in defaults, do the process to get a new username
        print("Discovering Bridges...")
        guard let url = URL(string: "https://discovery.meethue.com") else {return}
        print(url)
        DataManager.getFromURL(url: url) { (Results) in
            switch Results{
            case .success(let data):
                do {
                    self.discoveredBridges = try JSONDecoder().decode([Discovery].self, from: data)
                    self.rootView.updateTable(list: self.discoveredBridges.sorted(by: {$0.id < $1.id}), selectedBridge: self.selectedBridgeID)
                    //if a bridge is already selected, filter the bridges for the selected bridge
                    let filteredBridges = self.discoveredBridges.filter({$0.id == self.selectedBridgeID})
                    if let selectedBridge = filteredBridges.first{
                        self.selectedBridge(bridge: selectedBridge)
                    }
                    for bridge in self.discoveredBridges{
                        print("Bridge ID: \(bridge.id)")
                        print("Brdige IP: \(bridge.internalipaddress)")
                    }
                } catch let e{
                    print("Error: \(e)")
                }
            case .failure(let e): print("Error: \(e)")
            }
        }
    }
}

//MARK: - RootView - Bridge Delegate
extension MainVC: BridgeDelegate{
    func selectedBridge(bridge: Discovery) {
        print("selected bridge: \(bridge.internalipaddress) - \(bridge.id)")
        self.bridgeIP = bridge.internalipaddress
        var savedBridgesFromDefaults = self.defaults.object(forKey: Constants.savedBridges.rawValue) as? [String: [String: String]] ?? [String: [String: String]]()
        print("Saved Bridges before: \(savedBridgesFromDefaults)")

        let bridgeExists = savedBridgesFromDefaults[bridge.id] != nil
        
        if bridgeExists == true {
            print("Bridge exists in defaults")
            if let selectedBridge = savedBridgesFromDefaults[bridge.id]{
                if let username = selectedBridge[BridgeUser.username.rawValue],
                   let clientKey = selectedBridge[BridgeUser.clientKey.rawValue]{
                    print("bridge: \(bridge.internalipaddress) user: \(username)")
                    self.clientKey = clientKey
                    self.appOwner = username
                    self.defaults.set(bridge.id, forKey: Constants.selectedBridge.rawValue)
                    self.baseURL = "http://\(self.bridgeIP)/api/\(username)/"
                    self.rootView.updateTable(list: self.discoveredBridges.sorted(by: {$0.id < $1.id}), selectedBridge: bridge.id)
                    print("test to see if the bridge is responding")
                }
                if let safeBaseURL = self.baseURL{
                    DataManager.get(baseURL: safeBaseURL,
                                    HueSender: .config) { (results) in
                        switch results{
                        case .success(_): print("Successfully reached bridge")
                        case .failure(_):
                            DispatchQueue.main.async {
                                Alert.showBasic(title: "Error", message: "Unable to reach Bridge", vc: self)
                            }
                        }
                    }
                }
            }
        } else {
            print("bridge does not exist in defaults")
            print("setup new user")
            guard let url = URL(string: "http://\(self.bridgeIP)/api") else {return}
            let device = UIDevice()
            let httpBody: [String: Any] = [
                Keys.devicetype.rawValue: "HueLights#\(device.name)", // App name then device name
                Keys.generateclientkey.rawValue: true
            ]
            DataManager.createUser(baseURL: url,
                                   httpBody: httpBody) { Results in
                switch Results{
                case .success(let data):
                    do {
                        let responseFromBridge = try JSONDecoder().decode([CreateUserOnBridge].self, from: data)
                        for response in responseFromBridge{
                            if response.success != nil{
                                print("Success")
                                if let username = response.success?.username,
                                   let clientKey = response.success?.clientkey{
                                    print(username)
                                    let bridgeInfo = [
                                        BridgeUser.username.rawValue : username,
                                        BridgeUser.clientKey.rawValue : clientKey
                                    ]
                                    
                                    savedBridgesFromDefaults[bridge.id] = bridgeInfo
                                    self.defaults.set(savedBridgesFromDefaults, forKey: Constants.savedBridges.rawValue)
                                    self.defaults.set(bridge.id, forKey: Constants.selectedBridge.rawValue)
                                    print(savedBridgesFromDefaults.keys)
                                    print("Saved Bridges after: \(savedBridgesFromDefaults)")
                                    print("Added to defaults")
                                    DispatchQueue.main.async {
                                        Alert.showBasic(title: "Bridge Authorized", message: "Please make sure your Hue Bridge is up to date by using the official Philips Hue App to be able to use all the features. ", vc: self)
                                    }
                                    self.rootView.updateTable(list: self.discoveredBridges.sorted(by: {$0.id < $1.id}), selectedBridge: bridge.id)
                                    self.clientKey = clientKey
                                    self.appOwner = username
                                    self.baseURL = "http://\(self.bridgeIP)/api/\(username)/"
                                }
                                print("Username created!")
                            }
                            if response.error != nil{
                                print("Error")
                                
                                print(response.error?.description ?? "Error when creating username")
                                print("Show alert to press button on bridge")
                                DispatchQueue.main.async {
                                    Alert.showTapAlert(title: "Not Authorized", message: "Tap the big circle button on your bridge.", vc: self) {
                                        print("Done pressed.. reaching out to bridge again to get username")
                                        self.selectedBridge(bridge: bridge) // Go through the same function, the next time it should get a success if the button was pressed and not hit this point again.
                                    }
                                }
                            }
                        }
                    } catch let e{
                        print("Error decoding user: \(e)")
                    }
                case .failure(let e): print("Error Occurred creating user: \(e)")
                }
            }
        }
    }
}
