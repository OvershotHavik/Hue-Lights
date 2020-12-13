//
//  EditGroupVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/27/20.
//

import UIKit

protocol UpdateTitle: class {
    func updateTitle(newTitle: String)
}

protocol UpdatedHueResults: class{
    func getUpdatedHueResults(hueResults: [HueModel])
}

class EditGroupVC: UIViewController, BridgeInfoDelegate{
    var bridgeIP = String()
    var bridgeUser = String()
    weak var delegate : BridgeInfoDelegate?
    weak var updateTitleDelegate : UpdateTitle?
    weak var updateDelegate : UpdatedHueResults?
    fileprivate var rootView : EditItemView!
//    fileprivate var lightNameInGroup = [String]()
//    fileprivate var lightIDsInGroup = [String()]
    fileprivate var lightsInGroup : [HueModel.Light]?
    fileprivate var allLightsOnBridge: [HueModel.Light]
    fileprivate var newGroupName : String?
    fileprivate var group: HueModel.Groups
    init(group: HueModel.Groups, allLightsOnBridge: [HueModel.Light]) {
        self.group = group
        self.allLightsOnBridge = allLightsOnBridge
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewWillAppear(_ animated: Bool) {
        guard let delegate = delegate  else {
            print("setup delegate for EditGroupVC")
            return
        }
        bridgeIP = delegate.bridgeIP
        bridgeUser = delegate.bridgeUser
        //        getAllLightsOnBridge()
    }
    override func loadView() {
        rootView = EditItemView(itemName: group.name)
        self.view = rootView
        rootView.updateGroupDelegate = self
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        lightsInGroup = allLightsOnBridge.filter({return group.lights.contains($0.id)})
        if let safeLightsInGroup = lightsInGroup{
            let lightNames = safeLightsInGroup.map({$0.name})
            updateListOnView(list: lightNames)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if let safeNewGroupName = newGroupName{
            updateTitleDelegate?.updateTitle(newTitle: safeNewGroupName)
        }
        updateLightListInGroup()
    }
    
    //MARK: - Update Light List on rootView
    func updateListOnView(list: [String]){
        var text = String()
        for light in list{
            text += "\(light)\n"
        }
        rootView.updateLabel(text: text)
    }
    
    //MARK: - Update Light List In Group
    func updateLightListInGroup(){
        /*
         //for sending back to the previous VC to update the list when lights are changed
         guard let delegate = delegate  else {return}
         print("Get Info")
         guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)") else {return}
         print(url)
         
         DataManager.get(url: url) { (results) in
         switch results{
         case .success(let data):
         do {
         //                    var tempHueResults = [HueModel]()
         //                    let resultsFromBrdige = try JSONDecoder().decode(DecodedArray<HueModel>.self, from: data)
         //                    tempHueResults.append(resultsFromBrdige)
         //                    self.updateDelegate?.getUpdatedHueResults(hueResults: tempHueResults)
         } catch let e{
         print("Error getting info in edit group vc \(e)")
         }
         case .failure(let e):
         print("Error getting info in edit group vc \(e)")
         }
         }
         */
    }
    
}
//MARK: - Update Group Delegate
extension EditGroupVC: UpdateItem, SelectedLightsDelegate{
    func selectedLights(lights: [HueModel.Light]) {
        lightsInGroup = lights
        updateListOnView(list: lights.map{$0.name})
    }
    
    func deleteTapped(name: String) {
        
    }
    
    //MARK: - Get Light Names From Numbers
    func getLightNamesFromIDs(lightIDs: [String]) -> [String]{
        let filteredLights = allLightsOnBridge.filter{ return lightIDs.contains($0.id)}.map({$0.name})
        return filteredLights
    }
    
    //MARK: - Get Light ID's from Names
    func getLightIDFromNames(lightNames: [String]) -> [String]{
        let filteredLights = allLightsOnBridge.filter{ return lightNames.contains($0.name)}.map({$0.id})
        return filteredLights
    }
    
    
    //MARK: - Take user to edit lights in the group
    func editList() {
        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/groups") else {return}
        print(url)
        DataManager.get(url: url) { results in
            
            switch results{
            case .success(let data):
                do {
                    let groupsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Groups>.self, from: data)
                    let groups = groupsFromBridge.compactMap{$0}
                    for group in groups{
                        print("Lights in group:\(group.name) - \(group.lights)")
                    }
                    //Filter through groups to get all the lights currently assigned
                    let lightsInGroupsAlready = groups.flatMap{$0.lights}
                    //Filter through all lights on bridge to get the ones NOT in lights in groups already
                    var availableLights = self.allLightsOnBridge.filter {return !lightsInGroupsAlready.contains($0.id)}
//                    //Get the ID's of the available lights
//                    var availableLightIDs = availableLights.map({$0.id})
                    print("Available light count: \(availableLights.count)")
                    //Add the current groups' light ID's
                    if let safeLightsInGroup = self.lightsInGroup{
                        availableLights.append(contentsOf: safeLightsInGroup)
                        //get the names of the ID's
//                        let availableLightNames = self.getLightNamesFromIDs(lightIDs: availableLightIDs)
                        DispatchQueue.main.async {
    //                        let lightList = ModifyList(limit: 9999, selectedItems: self.lightNameInGroup, listItems: availableLightNames)
                            let lightList = ModifyLightsInGroupVC(limit: 999, selectedItems: safeLightsInGroup, listItems: availableLights)
                            lightList.delegate = self
                            lightList.selectedItemsDelegate = self
                            self.navigationController?.pushViewController(lightList, animated: true)
                        }
                    }
  
                } catch let e {
                    print("Error getting Groups: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
    }
    //MARK: - Save Tapped
    func saveTapped(name: String) {
        if let safeLightsInGroup = lightsInGroup{
            let lightIDsInGroup = safeLightsInGroup.map({$0.id})
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/groups/\(group.id)") else {return}
            print(url)
            var httpBody = [String: Any]()
            httpBody["name"] = name
            httpBody["lights"] = lightIDsInGroup
            DataManager.sendRequest(method: .put, url: url, httpBody: httpBody) { result in
                DispatchQueue.main.async {
                    switch result{
                    case .success(let response):
                        if response.contains("success"){
                            Alert.showBasic(title: "Saved!", message: "Successfully updated \(name)", vc: self)
                        } else {
                            Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                        }
                    case .failure(let e): print("Error occured: \(e)")
                    }
                }
            }
        }

    }
}
