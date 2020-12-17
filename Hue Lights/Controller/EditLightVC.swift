//
//  EditLightVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/29/20.
//

import UIKit

class EditLightVC: UIViewController{
    
    fileprivate var rootView : EditItemView!
    weak var updateDelegate : UpdateLights?

    lazy var alertClosure : (Result<String, NetworkError>, _ message: String) -> Void = {Result, message  in
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
    
    fileprivate var light : HueModel.Light
    fileprivate var groupsArray : [HueModel.Groups]?
    fileprivate var initialGroup : HueModel.Groups?
    fileprivate var newGroup : HueModel.Groups?
    fileprivate var noGroup = true
    fileprivate var baseURL : String
    fileprivate var showingInGroup: HueModel.Groups?
    
    init(baseURL: String, light: HueModel.Light, showingInGroup: HueModel.Groups?) {
        self.baseURL = baseURL
        self.light = light
        self.showingInGroup = showingInGroup
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - Load View
    override func loadView() {
        super.loadView()
        rootView = EditItemView(itemName: light.name)
        self.view = rootView
        rootView.updateGroupDelegate = self
        getGroups()
    }
    //MARK: - View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateLightListVC()
    }
    //MARK: - Update Light List VC
    func updateLightListVC(){
        if showingInGroup == nil {
            //Get all updated lights from bridge
            DataManager.get(baseURL: baseURL,
                            HueSender: .lights) { results in
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
        } else {
            //Get just the lights in the group, will update groupVC if this one was removed
            DataManager.get(baseURL: baseURL,
                            HueSender: .lights) { (results) in
                switch results{
                case .success(let data):
                    do {
                        let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                        let lights = lightsFromBridge.compactMap{ $0}
                        if let safeGroup = self.showingInGroup{
                            let lightsInGroup = lights.filter({return safeGroup.lights.contains($0.id)})
                            self.updateDelegate?.updateLightsDS(items: lightsInGroup)
                        }
                    } catch let e {
                        print("Error getting lights: \(e)")
                    }
                case .failure(let e): print(e)
                }
            }
        }
    }
    //MARK: -  Get Groups
    func getGroups(){
        DataManager.get(baseURL: baseURL,
                        HueSender: .groups) { results in
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

//MARK: - Update Item and Selected Group Delegate
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
    //MARK: - Edit List
    func editList() {
        DispatchQueue.main.async {
            if let safeGroupsArray = self.groupsArray{
                if  self.newGroup != nil{ // if a new group has been picked already, use that
                    let selectGroup = ModifyGroupVC(allGroups: safeGroupsArray, selectedGroup: self.newGroup)
//                    selectGroup.delegate = self
                    selectGroup.selectedGroupDelegate = self
                    self.navigationController?.pushViewController(selectGroup, animated: true)
                } else {
                    if self.noGroup == true { // initial was changed to no group, so blank selection
                        let selectGroup = ModifyGroupVC(allGroups: safeGroupsArray, selectedGroup: nil)
//                        selectGroup.delegate = self
                        selectGroup.selectedGroupDelegate = self
                        self.navigationController?.pushViewController(selectGroup, animated: true)
                    } else {
                        if self.initialGroup != nil{ // else use the initial group name
                            let selectGroup = ModifyGroupVC(allGroups: safeGroupsArray, selectedGroup: self.initialGroup)
//                            selectGroup.delegate = self
                            selectGroup.selectedGroupDelegate = self
                            self.navigationController?.pushViewController(selectGroup, animated: true)
                        }
                    }
                }
            }
        }
        print("edit tapped")
    }
    //MARK: - Save Tapped
    func saveTapped(name: String) {
        print("save tapped")
        if light.name != name{ // name changed, update the bridge
            let httpBody = ["name" : name]
            DataManager.updateLight(baseURL: baseURL,
                                    lightID: light.id,
                                    method: .put,
                                    httpBody: httpBody) { results in
                self.alertClosure(results, "Successfully updated \(name)")
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
    //MARK: - Add To Group
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
            groupLights.append(light.id)
            groupLights = groupLights.unique()
            let httpBody = ["lights":  groupLights]
            DataManager.modifyGroup(baseURL: baseURL,
                                    groupID: safeGroupID,
                                    method: .put,
                                    httpBody: httpBody) { results in
                self.alertClosure(results, "Added to \(newGroup.name)")
            }
        }
    }
    //MARK: - Remove from initial group
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
            if showingInGroup != nil{
                showingInGroup?.lights = safeGroupLights
            }
            let httpBody = ["lights": safeGroupLights]
            DataManager.modifyGroup(baseURL: baseURL,
                                    groupID: safeID,
                                    method: .put,
                                    httpBody: httpBody) { results in
                self.alertClosure(results, "Successfully removed from group")
            }
        }
    }
}
