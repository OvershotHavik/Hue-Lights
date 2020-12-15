//
//  MainVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/15/20.
//

import UIKit

class MainVC: UIViewController {
    lazy var testClosure : (Result<String, NetworkError>) -> Void = {Result in
        DispatchQueue.main.async {
            switch Result{
            case .success(let response):
                if response.contains("success"){
//                    Alert.showBasic(title: "Success", message: "Success Closure", vc: self)
                    //don't display an alert if successful
                } else {
                    Alert.showBasic(title: "Erorr occured", message: response, vc: self as UIViewController ) // will need changed later
                }
            case .failure(let e): print("Error occured: \(e)")
            }
        }
    }
    lazy var postClosure : (Result<String, NetworkError>, _ message: String) -> Void = {Result, message  in
        DispatchQueue.main.async {
            switch Result{
            case .success(let response):
                if response.contains("success"){
                    Alert.showBasic(title: "Success", message: message, vc: self)
                } else {
                    Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                }
            case .failure(let e): print("Error occured: \(e)")
            }
        }
    }
    
    fileprivate var rootView : MainView!
    internal var bridgeIP = String()
    internal var bridgeUser = String()
    internal var bridgeKey = String()
    var appOwner = String()
    let decoder = JSONDecoder()
    var baseURL : String?
    
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
        guard let baseURL = baseURL else {
            print("Base url not set in discovery")
            return
        }
        switch sender {
//MARK: - Lights
        case .lights:
            
            guard let url = URL(string: baseURL + HueSender.lights.rawValue) else {return}
            print(url)
            DataManager.getTest(baseURL: baseURL, HueSender: .lights) { results in
//            DataManager.get(url: url) { (results) in
                switch results{
                case .success(let data):
                    do {
                        let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                        let lights = lightsFromBridge.compactMap{ $0}
                        for light in lights{
                            print("Light id: \(light.id) - \(light.name)")
                        }
                        DispatchQueue.main.async {
                            let lightlistVC = LightsListVC(baseURL: baseURL, lightsArray: lights, showingGroup: nil)
//                            lightlistVC.delegate = self
                            lightlistVC.title = HueSender.lights.rawValue.capitalized
                            self.navigationController?.pushViewController(lightlistVC, animated: true)
                        }
                    } catch let e {
                        print("Error getting lights: \(e)")
                    }

                case .failure(let e): print(e)
                }
            }
//MARK: - Groups
        case .groups:
            guard let url = URL(string: baseURL + HueSender.groups.rawValue) else {return}
            print(url)
            DataManager.get(url: url) { results in
                
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
//                            groupListController.delegate = self
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
            guard let url = URL(string: baseURL + HueSender.schedules.rawValue) else {return}
            print(url)
            DataManager.get(url: url){results in
                switch results{
                case .success(let data):
                    do {
                        let schedulesFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Schedules>.self, from: data)
                        let schedules = schedulesFromBridge.compactMap {$0}
                        for schedule in schedules{
                            print("Schedule id: \(schedule.id) - \(schedule.name)")
                        }
                        DispatchQueue.main.async {
                            let scheduleList = ScheduleListVC(baseURL: baseURL, scheduleArray: schedules)
//                            scheduleList.delegate = self
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
        case .lightScenes:
//            DataManager.updateLight(baseURL: baseURL, lightID: "7", method: .put, httpBody: ["on": false], completionHandler: self.testClosure)
            let lightName = "Test name"
            DataManager.updateLight(baseURL: baseURL, lightID: "7", method: .put, httpBody: ["on": true]) { (Result) in
                self.postClosure(Result,"saved light \(lightName)")
            }
            /*
            guard let url = URL(string: baseURL + HueSender.scenes.rawValue) else {return}
            print(url)
            DataManager.get(url: url) { results in
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
                            let sceneList = SceneListVC(baseURL: baseURL, group: nil, lightsInGroup: [], sceneArray: ownedScenes)
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
 */
        default:
            print("not setup yet")
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
                        self.baseURL =  "http://\(self.bridgeIP)/api/\(self.bridgeUser)/"
                    }
                } catch let e{
                    print("Error: \(e)")
                }
            case .failure(let e): print("Error: \(e)")
            }
        }
    }
}
