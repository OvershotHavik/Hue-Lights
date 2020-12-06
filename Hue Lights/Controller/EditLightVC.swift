//
//  EditLightVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/29/20.
//

import UIKit

class EditLightVC: UIViewController, ListSelectionControllerDelegate{
    fileprivate var rootView : EditItemView!
    weak var delegate : ListSelectionControllerDelegate?
    weak var updateTitleDelegate : UpdateTitle?
    
    var sourceItems = [String]()
    var hueResults = [HueModel]()
    var bridgeIP = String()
    var bridgeUser = String()
    
    fileprivate var lightName : String
    fileprivate var lightKey : String?
    fileprivate var groupNames = [String]()
    fileprivate var initialGroup : String?
    fileprivate var newGroup : String?
    fileprivate var noGroup = false
    
    init(lightName: String) {
        self.lightName = lightName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        guard let delegate = delegate else {return}
        hueResults = delegate.hueResults
        bridgeIP = delegate.bridgeIP
        bridgeUser = delegate.bridgeUser
        rootView = EditItemView(itemName: lightName)
        self.view = rootView
        rootView.updateGroupDelegate = self
        getLightKey()
        getGroupNames()
        if let safeGroup = initialGroup{
            rootView.updateLabel(text: safeGroup)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func getLightKey(){
        for x in hueResults{
            for light in x.lights{
                if light.value.name == lightName{
                    lightKey = light.key
                }
            }
        }
    }
    
    func getGroupNames(){
        groupNames = []
        for x in hueResults{
            for group in x.groups{
                groupNames.append(group.value.name)
                if let safeKey = lightKey{
                    if group.value.lights.contains(safeKey){
                        initialGroup = group.value.name
                    }
                }
            }
        }
        sourceItems = groupNames.sorted()
    }
    
}


extension EditLightVC: UpdateItem, SelectedItems{
    func setSelectedItems(items: [String], ID: String) {
        newGroup = nil
        for item in items{
            newGroup = item
        }
        if items.count == 0{
            print("no group selected")
            noGroup = true
        }
        rootView.updateLabel(text: newGroup ?? "No group selected")
    }
    
    func editList() {
        DispatchQueue.main.async {
            if  let safeNewGroup = self.newGroup{ // if a new group has been picked already, use that
                let selectGroup = ModifyGroupList(limit: 1, selectedItems: [safeNewGroup])
                selectGroup.delegate = self
                selectGroup.selectedItemsDelegate = self
                self.navigationController?.pushViewController(selectGroup, animated: true)
            } else {
                if self.noGroup == true { // initial was changed to no group, so blank selection
                    let selectGroup = ModifyGroupList(limit: 1, selectedItems: [])
                    selectGroup.delegate = self
                    selectGroup.selectedItemsDelegate = self
                    self.navigationController?.pushViewController(selectGroup, animated: true)
                } else {
                    if let safeInitialGroup = self.initialGroup{ // else use the initial group name
                        let selectGroup = ModifyGroupList(limit: 1, selectedItems: [safeInitialGroup])
                        selectGroup.delegate = self
                        selectGroup.selectedItemsDelegate = self
                        self.navigationController?.pushViewController(selectGroup, animated: true)
                    }
                }
            }
        }
        print("edit tapped")
    }
    
    func saveTapped(name: String) {
        print("save tapped")
        if lightName != name{ // name changed, update the bridge
            if let safeKey = lightKey{
                guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/lights/\(safeKey)") else {return}
                print(url)
                let httpBody = ["name" : name]
                DataManager.put(url: url, httpBody: httpBody) { result in
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
        if let safeKey = lightKey{
            if let safeInitialGroup = initialGroup{
                if newGroup != safeInitialGroup{
                    print("new group name is different than initial")
                    removeFromInitialGroup() // group changed, so remove from previous group first
                }
                print("Group changed")
                var groupLights = [String]()
                var groupNumber = String()
                for x in hueResults{
                    for group in x.groups{
                        if group.value.name == newGroup{
                            groupLights = group.value.lights
                            groupNumber = group.key
                        }
                    }
                }
                
                guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/groups/\(groupNumber)") else {return}
                print(url)
                groupLights.append(safeKey)
                groupLights = groupLights.unique()
                let httpBody = ["lights":  groupLights]
                DataManager.put(url: url, httpBody: httpBody) { result in
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
        guard let safeKey = lightKey else {return}
        var groupLights : [String]?
        var groupNumber : String?
        for x in hueResults{
            for group in x.groups{
                if group.value.name == initialGroup{
                    groupLights = group.value.lights
                    groupNumber = group.key
                }
            }
        }
        if var safeGroupLights = groupLights,
           let safeGroupNumber = groupNumber{ // if no initial group, skip the removal
            safeGroupLights = safeGroupLights.filter {$0 != safeKey}.unique()
            
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/groups/\(safeGroupNumber)") else {return}
            print(url)
            let httpBody = ["lights": safeGroupLights]
            DataManager.put(url: url, httpBody: httpBody) { result in
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
