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
    
    fileprivate var lightName : String
    fileprivate var lightID : String
    fileprivate var groupsArray : [HueModel.Groups]?
    fileprivate var initialGroup : String?
    fileprivate var newGroup : String?
    fileprivate var noGroup = true
    
    init(lightName: String, lightID: String) {
        self.lightName = lightName
        self.lightID = lightID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        guard let delegate = delegate else {return}
        bridgeIP = delegate.bridgeIP
        bridgeUser = delegate.bridgeUser
        rootView = EditItemView(itemName: lightName)
        self.view = rootView
        rootView.updateGroupDelegate = self
//        getLightKey()
        getGroups()
        if let safeGroup = initialGroup{
            rootView.updateLabel(text: safeGroup)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    /*
    func getLightKey(){
        if let hueResults = hueResults{
            for light in hueResults.lights{
                if light.value.name == lightName{
                    lightKey = light.key
                }
            }
        }
    }
    */
    func getGroups(){
        groupsArray = []
        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/groups") else {return}
        print(url)
        DataManager.get(url: url) { results in
            switch results{
            case .success(let data):
                do {
                    let groupsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Groups>.self, from: data)
                    self.groupsArray = groupsFromBridge.compactMap{$0}
                    
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
        newGroup = nil
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
                if  let safeNewGroup = self.newGroup{ // if a new group has been picked already, use that
                    let selectGroup = ModifyGroupList(limit: 1, selectedItems: [safeNewGroup], groupsArray: safeGroupsArray)
                    selectGroup.delegate = self
                    selectGroup.selectedItemsDelegate = self
                    self.navigationController?.pushViewController(selectGroup, animated: true)
                } else {
                    if self.noGroup == true { // initial was changed to no group, so blank selection
                        let selectGroup = ModifyGroupList(limit: 1, selectedItems: [], groupsArray: safeGroupsArray)
                        selectGroup.delegate = self
                        selectGroup.selectedItemsDelegate = self
                        self.navigationController?.pushViewController(selectGroup, animated: true)
                    } else {
                        if let safeInitialGroup = self.initialGroup{ // else use the initial group name
                            let selectGroup = ModifyGroupList(limit: 1, selectedItems: [safeInitialGroup], groupsArray: safeGroupsArray)
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
        if lightName != name{ // name changed, update the bridge

                guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/lights/\(lightID)") else {return}
                print(url)
                let httpBody = ["name" : name]
                DataManager.sendRequest(method: .put, url: url, httpBody: httpBody) { result in
                    DispatchQueue.main.async {
                        switch result{
                        case .success(let response):
                            if response.contains("Success") || response.contains("success") {
                                Alert.showBasic(title: "Saved!", message: "Successfully updated \(self.lightName)", vc: self)
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
                if newGroup != safeInitialGroup{
                    print("new group name is different than initial")
                    removeFromInitialGroup() // group changed, so remove from previous group first
                }
                print("Group changed")
                
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
                    groupLights.append(lightID)
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
//        if let hueResults = hueResults{
//            for group in hueResults.groups{
//                if group.value.name == initialGroup{
//                    groupLights = group.value.lights
//                    groupNumber = group.key
//                }
//            }
//        }
        if var safeGroupLights = groupLights,
           let safeID = groupID{ // if no initial group, skip the removal
            safeGroupLights = safeGroupLights.filter {$0 != lightID}.unique()
            
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
