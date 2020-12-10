//
//  MainVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/15/20.
//

import UIKit

class MainVC: UIViewController, ListSelectionControllerDelegate {
    var hueResults : HueModel?
    var sourceItems = [String]()
    
    fileprivate var rootView : MainView!
    internal var bridgeIP = String()
    internal var bridgeUser = String()
    internal var bridgeKey = String()
    var appOwner = String()
    let decoder = JSONDecoder()
    
    override func loadView() {
        super.loadView()
        rootView = MainView()
        self.view = rootView
        rootView.getDelegate = self
        bridgeUser = "0ZaZRrSyiEoQYiw05AKrHmKsOuIcpcu1W8mb0Qox" // Steve's Bridge Username
        bridgeKey = "68D5D9EC03F6AD7A73F95D4E148102E1" // Steve's Bridge Key
        appOwner = "0ZaZRrSyiEoQYiw05AKrHmKsOuIcpcu1W8mb0Qox"
        discovery()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension MainVC: GetDelegate{
    func getTapped(sender: HueSender) {
        print("Get Info")
        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)") else {return}
        print(url)
        DataManager.get(url: url) { (results) in
            switch results{
            case .success(let data):
                do {
                    self.sourceItems = []
                    self.hueResults = nil
                    let resultsFromBrdige = try JSONDecoder().decode(HueModel.self, from: data)
                    self.hueResults = resultsFromBrdige
                    switch sender{
                    case .lights:
                        for light in resultsFromBrdige.lights{
                            
                            print("=================================================")
                            print("Key: \(light.key) light name: \(light.value.name), state on: \(light.value.state.on), Brightness: \(light.value.state.bri), is reachable: \(light.value.state.reachable)")
                            
                            if let safeHue = light.value.state.hue,
                               let safeSat = light.value.state.sat{
                                print("\(light.value.name)'s Hue: \(safeHue), Saturtation: \(safeSat)")
                            
                            }
                            if let safeXY = light.value.state.xy{
                                print("xy: \(safeXY)")
                            }
                            self.sourceItems.append(light.value.name)
                        }
//                        let lights = try JSONDecoder().decode([String:HueModel.Light].self, from: data)
                        
                        let lightsArray: [HueModel.Light] = Array(resultsFromBrdige.lights.values)
//                        var array = lightsArray
                        DispatchQueue.main.async {
                            let lightlistVC = LightsListVC(lightsArray: lightsArray, showingGroup: false)
                            lightlistVC.delegate = self
                            lightlistVC.title = HueSender.lights.rawValue
                            self.navigationController?.pushViewController(lightlistVC, animated: true)
                        }
                        
//MARK: - Groups
                    case .groups:
                        for group in resultsFromBrdige.groups{
                            print("Key: \(group.key) - Group Name: \(group.value.name)")
//                            self.sourceItems.append(group.value.name)
                        }
                        let groupArray = Array(resultsFromBrdige.groups.values)
                        DispatchQueue.main.async {
                            let groupListController = GroupsListVC(groupsArray: groupArray)
                            groupListController.delegate = self
                            groupListController.title = HueSender.groups.rawValue
                            self.navigationController?.pushViewController(groupListController, animated: true)
                        }
                        
//MARK: - Schedules
                    case .schedules:
                        for schedule in resultsFromBrdige.schedules{
                            print("Key: \(schedule.key) - Schedule Name: \(schedule.value.name)")
                            self.sourceItems.append(schedule.value.name)
                        }
                        DispatchQueue.main.async {
                            let scheduleList = ScheduleListVC()
                            scheduleList.delegate = self
                            scheduleList.title = HueSender.schedules.rawValue
                            self.navigationController?.pushViewController(scheduleList, animated: true)
                        }
//MARK: - Light Scenes
                    case .lightScenes:
                        print("Light Scenes")
                        for scene in resultsFromBrdige.scenes{
//                            print("scen: \(scene.value.name) type: \(scene.value.type)")
                            if scene.value.type == "LightScene"{
                                if scene.value.owner == self.appOwner{ // this app owner
                                    print("Light scene: \(scene.value.name)")
                                    self.sourceItems.append(scene.value.name)
                                }
                            }
                        }
                        DispatchQueue.main.async {
                            let sceneList = SceneListVC(groupNumber: "", lightsInGroup: [""])
                            sceneList.delegate = self
                            sceneList.title = HueSender.lightScenes.rawValue
                            self.navigationController?.pushViewController(sceneList, animated: true)
                        }
                        
                    default: print("Not setup in get tapped on main vc")
                    }
                } catch let e {
                    print("Error: \(e)")
                }
            case .failure(let e): print("Error getting info: \(e)")
            }
        }
    }
}
//MARK: - Discovery - Run once
extension MainVC{
    func discovery(){
        //runs at start up. If the bridge IP is different then what is stored in defaults, do the process to get a new username ----- not setup yet
        
        //will need to get app owner through this as well later for light scenes to work
        print("Discovering Bridges...")
        guard let url = URL(string: "https://discovery.meethue.com") else {return}
        print(url)
        DataManager.get(url: url) { (Results) in
            switch Results{
            case .success(let data):
                do {
                    let bridges = try JSONDecoder().decode([Discovery].self, from: data)
                    for bridge in bridges{
                        print("Bridge ID: \(bridge.id)")
                        print("Brdige IP: \(bridge.internalipaddress)")
                        self.bridgeIP = bridge.internalipaddress
                    }
                } catch let e{
                    print("Error: \(e)")
                }
            case .failure(let e): print("Error: \(e)")
            }
        }
    }
}
