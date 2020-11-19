//
//  MainVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/15/20.
//

import UIKit

class MainVC: UIViewController, ListSelectionControllerDelegate {
    var hueLights = [HueModel.Light]()
    var sourceItems = [String]()
    
    fileprivate var rootView : MainView!
    fileprivate var bridgeIP = String()
    fileprivate var bridgeUser = String()
    fileprivate let rest = RestManager()
    let decoder = JSONDecoder()
//    fileprivate let lightsArray = [String]()
    
    override func loadView() {
        super.loadView()
        rootView = MainView()
        self.view = rootView
        rootView.getDelegate = self
//        bridgeIP = "192.168.1.175"
        bridgeUser = "kagaOXDCsywZ7IbOS3EJkOg1r5CD4DBvvVc9lKC7"
//        getTapped()
        discovery()
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}

extension MainVC: GetDelegate{
    func getTapped() {
        
        print("Get info")
        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)") else {return}
        print(url)
        rest.makeRequest(toURL: url, withHttpMethod: .get) { (results) in
            if let data = results.data{
                do {
                    let resultsFromBrdige = try JSONDecoder().decode(HueModel.self, from: data)
                    
                    for light in resultsFromBrdige.lights{
                        print("light name: \(light.value.name), state on: \(light.value.state.on), Brightness: \(light.value.state.bri), is reachable: \(light.value.state.reachable)")
                        self.sourceItems.append(light.value.name)
                        self.hueLights.append(light.value)
                    }
                    
                    DispatchQueue.main.async {
                        let listController = ListController()
                        listController.delegate = self
                        self.navigationController?.pushViewController(listController, animated: true)
                    }

                } catch let e {
                    print("Error: \(e)")
                }
                guard let lightsData = try? self.decoder.decode([HueModel].self, from: data) else {return}
                for light in lightsData{
                    print("Light name: \(light)")
                }
            }
        }
    }
    
    
}
//MARK: - Discovery - Run once
extension MainVC{
    func discovery(){
        // should only be run on the first time a user starts the app, and stored in defaults. Still need to get a user made as well
        print("Discovering Bridges...")
        guard let url = URL(string: "https://discovery.meethue.com") else {return}
        print(url)
        DataManager.fetchData(url: url) { (Results) in
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
