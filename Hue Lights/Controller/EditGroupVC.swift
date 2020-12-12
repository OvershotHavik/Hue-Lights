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
    fileprivate var lightNameInGroup = [String]()
    fileprivate var lightNumbersInGroup = [String()]
    fileprivate var allLightsOnBridge: [HueModel.Light]?
    fileprivate var newGroupName : String?
    internal var sourceItems = [String]()
    fileprivate var group: HueModel.Groups
    init(group: HueModel.Groups) {
        self.group = group
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = rootView
        rootView.updateGroupDelegate = self
        lightNameInGroup = getLightNamesFromIDs(lightIDs: group.lights)
        updateListOnView(list: lightNameInGroup)
//        lightNumbersInGroup = getNumberFromName(lightNames: lightNameInGroup)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let delegate = delegate  else {
            print("setup delegate for EditGroupVC")
            return
        }
        rootView = EditItemView(itemName: group.name)
        bridgeIP = delegate.bridgeIP
        bridgeUser = delegate.bridgeUser
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
extension EditGroupVC: UpdateItem, SelectedItems{
    func deleteTapped(name: String) {
        
    }
    
    func setSelectedItems(items: [String], ID: String) {
        let names = items.sorted { $0 < $1}
        var text = String()
        for light in names{
            text += "\(light)\n"
        }
        rootView.updateLabel(text: text)
    }
    
    
    func getAllLightsOnBridge(){
        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/lights") else {return}
        print(url)
        DataManager.get(url: url) { (results) in
            switch results{
            case .success(let data):
                do {
                    let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                    self.allLightsOnBridge = lightsFromBridge.compactMap{ $0}
                } catch let e {
                    print("Error getting lights: \(e)")
                }

            case .failure(let e): print(e)
            }
        }
    }
    //MARK: - Get Light Names From Numbers
    func getLightNamesFromIDs(lightIDs: [String]) -> [String]{
        if let allLights = allLightsOnBridge{
            let filteredLights = allLights.filter{ return lightIDs.contains($0.id)}.map({$0.name})
            return filteredLights
        } else {
            return []
        }
        /*
        var lightNames = [String]()
//        var lightsInGroupsAlready = lightIDs
        
        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/lights") else {return []}
        print(url)
        DataManager.get(url: url) { (results) in
            switch results{
            case .success(let data):
                do {
                    let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                    let lights = lightsFromBridge.compactMap{ $0}
                    let filteredLights = lights.filter{ return lightIDs.contains($0.id)}
                    lightNames = filteredLights.map({$0.name})
                } catch let e {
                    print("Error getting lights: \(e)")
                }

            case .failure(let e): print(e)
            }
        }
 */
        /*
        if let hueResults = hueResults{
//            for group in hueResults.groups{
//                if group.value.name == groupName{
//                    for light in group.value.lights{
//                        lightNumbers.append(light) // get number of the lights that are currently in the group
//                    }
//                }
//                lightsInGroupsAlready.append(contentsOf: group.value.lights)
//            }
            print("Lights in groups already: \(lightsInGroupsAlready)")
            for light in hueResults.lights{
                if lightsInGroupsAlready.contains(light.key){
                } else {
                    print("\(light.value.name) added to list")
                    sourceItems.append(light.value.name)
                }
                if lightNumbers.contains(light.key){ // based on the number, get the name of the light
                    lightNames.append(light.value.name)
                    sourceItems.append(light.value.name) // adds lights in this group
                }
            }
        }
 */
    }
    
    //MARK: - Get Light ID's from Names
    func getLightIDFromNames(lightNames: [String]) -> [String]{
        if let allLights = allLightsOnBridge{
            let filteredLights = allLights.filter{ return lightNames.contains($0.name)}.map({$0.id})
            return filteredLights
        } else {
            return []
        }
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
                        print("Group name: \(group.name), Group id: \(group.id)")
                    }
                    DispatchQueue.main.async {
                        let lightList = ModifyGroupList(limit: 9999, selectedItems: self.lightNameInGroup, groupsArray: groups)
                        lightList.delegate = self
                        lightList.selectedItemsDelegate = self
                        self.navigationController?.pushViewController(lightList, animated: true)
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
        
        self.lightNumbersInGroup = getLightIDFromNames(lightNames: self.lightNameInGroup)
        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/groups/\(group.id)") else {return}
        print(url)
        var httpBody = [String: Any]()
        httpBody["name"] = name
        httpBody["lights"] = self.lightNumbersInGroup
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
