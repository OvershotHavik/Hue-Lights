//
//  EditLightVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/29/20.
//

import UIKit

class EditLightVC: UIViewController, BridgeInfoDelegate{
    
    fileprivate var rootView : EditItemView!
    weak var delegate : BridgeInfoDelegate?
    weak var updateDelegate : UpdateLights?
//    weak var updateTitleDelegate : UpdateTitle?
    
    var bridgeIP = String()
    var bridgeUser = String()
    
    fileprivate var light : HueModel.Light
    fileprivate var groupsArray : [HueModel.Groups]?
    fileprivate var initialGroup : HueModel.Groups?
    fileprivate var newGroup : HueModel.Groups?
    fileprivate var noGroup = true
    
    init(light: HueModel.Light) {
        self.light = light
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        guard let delegate = delegate else {return}
        bridgeIP = delegate.bridgeIP
        bridgeUser = delegate.bridgeUser
        rootView = EditItemView(itemName: light.name)
        self.view = rootView
        rootView.updateGroupDelegate = self
        getGroups()
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateLightListVC()
    }
    
    func updateLightListVC(){
        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/lights") else {return}
        print(url)
        DataManager.get(url: url) { (results) in
            switch results{
            case .success(let data):
                do {
                    let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                    let lights = lightsFromBridge.compactMap{ $0}
                    self.updateDelegate?.updateLightsDS(items: lights)
                } catch let e {
                    print("Error getting lights: \(e)")
                }

            case .failure(let e): print(e)
            }
        }
    }
    
    func getGroups(){
        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/groups") else {return}
        print(url)
        DataManager.get(url: url) { results in
            switch results{
            case .success(let data):
                do {
                    let groupsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Groups>.self, from: data)
                    self.groupsArray = groupsFromBridge.compactMap{$0}
                    if let safeGroupsArray = self.groupsArray{
                        let filtered = safeGroupsArray.filter{$0.lights.contains(self.light.id)}
                        self.initialGroup = filtered.first
                        if let safeGroup = self.initialGroup{
                            self.rootView.updateLabel(text: safeGroup.name)
                            self.noGroup = false
                        } else {
                            self.rootView.updateLabel(text: "No group selected")
                            self.noGroup = true
                        }
                    }
                } catch let e {
                    print("Error getting Groups: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
    }
}


extension EditLightVC: UpdateItem, SelectedGroupDelegate{
    func selectedGroup(group: HueModel.Groups?) {
        if let safeGroup = group{
            newGroup = safeGroup
        } else {
            newGroup = nil
            noGroup = true
        }
        if let safeNewGroup = newGroup{
            rootView.updateLabel(text: safeNewGroup.name)
            noGroup = false
        } else {
            rootView.updateLabel(text: "No group selected")
        }
    }
    
    
    func deleteTapped(name: String) {
        
    }
    
    func editList() {
        
        
        DispatchQueue.main.async {
            if let safeGroupsArray = self.groupsArray{
                if  self.newGroup != nil{ // if a new group has been picked already, use that
                    let selectGroup = ModifyGroupVC(allGroups: safeGroupsArray, selectedGroup: self.newGroup)
                    selectGroup.delegate = self
                    selectGroup.selectedGroupDelegate = self
                    self.navigationController?.pushViewController(selectGroup, animated: true)
                } else {
                    if self.noGroup == true { // initial was changed to no group, so blank selection
                        let selectGroup = ModifyGroupVC(allGroups: safeGroupsArray, selectedGroup: nil)
                        selectGroup.delegate = self
                        selectGroup.selectedGroupDelegate = self
                        self.navigationController?.pushViewController(selectGroup, animated: true)
                    } else {
                        if self.initialGroup != nil{ // else use the initial group name
                            let selectGroup = ModifyGroupVC(allGroups: safeGroupsArray, selectedGroup: self.initialGroup)
                            selectGroup.delegate = self
                            selectGroup.selectedGroupDelegate = self
                            self.navigationController?.pushViewController(selectGroup, animated: true)
                        }
                    }
                }
            }
        }
        print("edit tapped")
 
    }
    
    func saveTapped(name: String) {
        print("save tapped")
        if light.name != name{ // name changed, update the bridge
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/lights/\(light.id)") else {return}
            print(url)
            let httpBody = ["name" : name]
            DataManager.sendRequest(method: .put, url: url, httpBody: httpBody) { result in
                DispatchQueue.main.async {
                    switch result{
                    case .success(let response):
                        if response.contains("Success") || response.contains("success") {
                            Alert.showBasic(title: "Saved!", message: "Successfully updated \(name)", vc: self)
                        } else {
                            Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                        }
                    case .failure(let e): print("Error occured: \(e)")
                    }
                }
            }
        }
        
        
        if let safeNewGroup = newGroup{
            addToGroup(newGroup: safeNewGroup)
        } else {
            if initialGroup == nil{
                print("Nothing happens since no initial group and no new selected")
            } else {
                print("new group wasn't selected, removing from \(initialGroup?.name ?? "")")
                removeFromInitialGroup()
            }
        }
    }
    func addToGroup(newGroup: HueModel.Groups){
        
        
        if let safeInitialGroup = initialGroup{
            print("Group changed")
            if newGroup != safeInitialGroup{
                print("new group name is different than initial")
                removeFromInitialGroup() // group changed, so remove from previous group first
            }
        }
        
        
        var groupLights = [String]()
        var groupID : String?
        if groupsArray != nil{
            let filteredGroups = groupsArray?.filter({$0 == newGroup})
            if let safeLights = filteredGroups?[0].lights{
                groupLights = safeLights
            }
            if let safeID = filteredGroups?[0].id{
                groupID = safeID
            }
        }
        if let safeGroupID = groupID{
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/groups/\(safeGroupID)") else {return}
            print(url)
            groupLights.append(light.id)
            groupLights = groupLights.unique()
            let httpBody = ["lights":  groupLights]
            DataManager.sendRequest(method: .put, url: url, httpBody: httpBody) { result in
                DispatchQueue.main.async {
                    switch result{
                    case .success(let response):
                        if response.contains("success"){
                            Alert.showBasic(title: "Success", message: "Added to \(newGroup.name)", vc: self)
                        } else {
                            Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                        }
                    case .failure(let e): print("Error occured: \(e)")
                    }
                }
            }
        }
    }
    
    func removeFromInitialGroup(){
        print("remove from initial group")
        var groupLights : [String]?
        var groupID : String?
        if groupsArray != nil{
            let filteredGroups = groupsArray?.filter({$0 == initialGroup})
            if let safeLights = filteredGroups?[0].lights{
                groupLights = safeLights
            }
            if let safeID = filteredGroups?[0].id{
                groupID = safeID
            }
        }
        if var safeGroupLights = groupLights,
           let safeID = groupID{ // if no initial group, skip the removal
            safeGroupLights = safeGroupLights.filter {$0 != light.id}.unique()
            
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/groups/\(safeID)") else {return}
            print(url)
            let httpBody = ["lights": safeGroupLights]
            DataManager.sendRequest(method: .put, url: url, httpBody: httpBody) { result in
                DispatchQueue.main.async {
                    switch result{
                    case .success(let response):
                        if response.contains("success"){
                            if self.newGroup == nil{
                                Alert.showBasic(title: "Success", message: "Successfully removed from group", vc: self)
                            }
                            //don't display an alert if successful
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
