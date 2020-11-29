//
//  MainVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/15/20.
//

import UIKit

class MainVC: UIViewController, ListSelectionControllerDelegate {
    var hueResults = [HueModel]()
    var sourceItems = [String]()
    
    fileprivate var rootView : MainView!
    internal var bridgeIP = String()
    internal var bridgeUser = String()
    let decoder = JSONDecoder()
    
    
    //Color picker setup
    private var pickedColor = UIColor.systemBlue
    private var colorPicker = UIColorPickerViewController()
    
    override func loadView() {
        super.loadView()
        rootView = MainView()
        self.view = rootView
        rootView.getDelegate = self
        bridgeUser = "kagaOXDCsywZ7IbOS3EJkOg1r5CD4DBvvVc9lKC7" // Steve's Bridge Username
        discovery()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension MainVC: GetDelegate{
    func getTapped(sender: String) {
        print("Get Info")
        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)") else {return}
        print(url)
        DataManager.get(url: url) { (results) in
            switch results{
            case .success(let data):
                do {
                    self.sourceItems = []
                    self.hueResults = []
                    let resultsFromBrdige = try JSONDecoder().decode(HueModel.self, from: data)
                    self.hueResults.append(resultsFromBrdige)
                    switch sender{
                    case UI.lights:
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
                        DispatchQueue.main.async {
                            let lightlistVC = LightsListVC()
                            lightlistVC.delegate = self
                            lightlistVC.title = UI.lights
                            self.navigationController?.pushViewController(lightlistVC, animated: true)
                        }
                    case UI.groups:
                        for group in resultsFromBrdige.groups{
                            print("Key: \(group.key) - Group Name: \(group.value.name)")
                            self.sourceItems.append(group.value.name)
                        }
                        
                        DispatchQueue.main.async {
                            let GroupListController = GroupsListVC()
                            GroupListController.delegate = self
                            GroupListController.title = UI.groups
                            self.navigationController?.pushViewController(GroupListController, animated: true)
                        }
                    case UI.scenese: print("Not setup yet")
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
//MARK: - color picker
extension MainVC : UIColorPickerViewControllerDelegate{
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        pickedColor = viewController.selectedColor
        view.backgroundColor = pickedColor
    }
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        print("color picker controler did finish")
    }
    private func selectColor(){
        colorPicker.supportsAlpha = true
        colorPicker.selectedColor = pickedColor
        self.present(colorPicker, animated: true)
    }
    private func setupBarButton(){
        let pickColorAction = UIAction(title: "Pick Color") { _ in
            self.selectColor()
        }
        let pickColorBarButton = UIBarButtonItem(image: UIImage(systemName: "eyedropper"), primaryAction: pickColorAction)
        navigationItem.rightBarButtonItem = pickColorBarButton
    }
}
