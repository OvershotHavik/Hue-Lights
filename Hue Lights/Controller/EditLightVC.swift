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
    weak var updateTitleDelegate : UpdateTitle?
    
    
    var bridgeIP = String()
    var bridgeUser = String()
    
    fileprivate var light : HueModel.Light
    fileprivate var groupsArray : [HueModel.Groups]?
    fileprivate var initialGroup : String?
    fileprivate var newGroup : String?
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
                        let filtered = safeGroupsArray.filter{$0.lights.contains(self.light.id)}.map({$0.name})
                        self.initialGroup = filtered.first
                        if let safeGroup = self.initialGroup{
                            self.rootView.updateLabel(text: safeGroup)
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


extension EditLightVC: UpdateItem, SelectedItems{
    
    func deleteTapped(name: String) {
        
    }
    
    func setSelectedItems(items: [String], ID: String) {
        for item in items{
            newGroup = item
        }
        if items.count == 0{
            print("no group selected")
            noGroup = true
        } else {
            noGroup = false
        }
        rootView.updateLabel(text: newGroup ?? "No group selected")
    }
    
    func editList() {
        DispatchQueue.main.async {
            if let safeGroupsArray = self.groupsArray{
                let groupNames = safeGroupsArray.map({$0.name})
                if  let safeNewGroup = self.newGroup{ // if a new group has been picked already, use that
                    let selectGroup = ModifyList(limit: 1, selectedItems: [safeNewGroup], listItems: groupNames)
                    selectGroup.delegate = self
                    selectGroup.selectedItemsDelegate = self
                    self.navigationController?.pushViewController(selectGroup, animated: true)
                } else {
                    if self.noGroup == true { // initial was changed to no group, so blank selection
                        let selectGroup = ModifyList(limit: 1, selectedItems: [], listItems: groupNames)
                        selectGroup.delegate = self
                        selectGroup.selectedItemsDelegate = self
                        self.navigationController?.pushViewController(selectGroup, animated: true)
                    } else {
                        if let safeInitialGroup = self.initialGroup{ // else use the initial group name
                            let selectGroup = ModifyList(limit: 1, selectedItems: [safeInitialGroup], listItems: groupNames)
                            selectGroup.delegate = self
                            selectGroup.selectedItemsDelegate = self
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
                print("new group wasn't selected, removing from \(initialGroup ?? "")")
                removeFromInitialGroup()
            }
        }
    }
    func addToGroup(newGroup: String){
        
        
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
            let filteredGroups = groupsArray?.filter({$0.name == newGroup})
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
                            Alert.showBasic(title: "Success", message: "Added to \(newGroup)", vc: self)
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
            let filteredGroups = groupsArray?.filter({$0.name == initialGroup})
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
