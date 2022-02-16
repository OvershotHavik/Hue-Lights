//
//  EditGroupVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/27/20.
//

import UIKit

protocol UpdateTitle: AnyObject {
    func updateTitle(newTitle: String)
}

class EditGroupVC: UIViewController{
    weak var updateTitleDelegate : UpdateTitle?
    weak var updateLightsDelegate : UpdateLights?
    
    lazy var alertClosure : (Result<String, NetworkError>, _ message: String) -> Void = {Result, message  in
        DispatchQueue.main.async {
            switch Result{
            case .success(let response):
                if response.contains("success"){
                    Alert.showBasic(title: "Success", message: message, vc: self)
                } else {
                    Alert.showBasic(title: "Error occurred", message: response, vc: self) // will need changed later
                }
            case .failure(let e): print("Error occurred: \(e)")
            }
        }
    }
    
    fileprivate var rootView : EditItemView!
    fileprivate var lightsInGroup : [HueModel.Light]?
    fileprivate var allLightsOnBridge: [HueModel.Light]
    fileprivate var newGroupName : String?
    fileprivate var group: HueModel.Groups?
    fileprivate var baseURL : String
    init(baseURL: String, group: HueModel.Groups?, allLightsOnBridge: [HueModel.Light]) {
        self.baseURL = baseURL
        self.group = group
        self.allLightsOnBridge = allLightsOnBridge
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - Load View
    override func loadView() {
        rootView = EditItemView(itemName: group?.name ?? "")
        self.view = rootView
        rootView.updateItemDelegate = self
        rootView.tfChangeName.delegate = self
    }
    //MARK: - View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        if let safeGroup = group{
            lightsInGroup = allLightsOnBridge.filter({return (safeGroup.lights.contains($0.id))})
        }
        if let safeLightsInGroup = lightsInGroup{
            let lightNames = safeLightsInGroup.map({$0.name})
            updateListOnView(list: lightNames)
        }
    }
    //MARK: - View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if let safeNewGroupName = newGroupName{
            updateTitleDelegate?.updateTitle(newTitle: safeNewGroupName)
        }
        if let safeLightsInGroup = lightsInGroup{
            updateLightsDelegate?.updateLightsDS(items: safeLightsInGroup)
        }
    }
    
    //MARK: - Update Light List on rootView
    func updateListOnView(list: [String]){
        var text = String()
        for light in list.sorted(by: {$0 < $1}){
            text += "\(light)\n"
        }
        rootView.updateLabel(text: text)
    }
    
}
//MARK: - Update Group Delegate
extension EditGroupVC: UpdateItem, SelectedLightsDelegate{
    func identifyTapped() {
        print("ID tapped in edit group vc")
    }
    
    func selectedLights(lights: [HueModel.Light]) {
        lightsInGroup = lights
        updateListOnView(list: lights.map{$0.name})
    }
    
    func deleteTapped(name: String) {
        Alert.showConfirmDelete(title: "Delete Group", message: "Are you sure you want to delete \(name)?", vc: self) {

            print("delete the scene when delete is pressed")
            if let safeGroup = self.group{
                DataManager.modifyGroup(baseURL: self.baseURL,
                                        groupID: safeGroup.id,
                                        method: .delete,
                                        httpBody: [:]) { results in
                    self.alertClosure(results, "Successfully deleted \(safeGroup.name)")
                }
            }
        }
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
        DataManager.get(baseURL: baseURL,
                        HueSender: .groups) { results in
            switch results{
            case .success(let data):
                do {
                    let groupsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Groups>.self, from: data)
                    let groups = groupsFromBridge.compactMap{$0}
                    //Filter through groups to get all the lights currently assigned
                    let lightsInGroupsAlready = groups.flatMap{$0.lights}
                    //Filter through all lights on bridge to get the ones NOT in lights in groups already
                    var availableLights = self.allLightsOnBridge.filter {return !lightsInGroupsAlready.contains($0.id)}
                    if let safeLightsInGroup = self.lightsInGroup{
                        //add lights that are already in this group
                        availableLights.append(contentsOf: safeLightsInGroup)
                    }
                    DispatchQueue.main.async {
                        let lightList = ModifyLightsInGroupVC(limit: 999,
                                                              selectedItems: self.lightsInGroup ?? [],
                                                              lightsArray: availableLights)
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
        if let safeLightsInGroup = lightsInGroup{
            let lightIDsInGroup = safeLightsInGroup.map({$0.id})
            var httpBody = [String: Any]()
            httpBody[Keys.name.rawValue] = name
            httpBody[Keys.lights.rawValue] = lightIDsInGroup
            if let safeGroup = group{
                DataManager.modifyGroup(baseURL: baseURL,
                                        groupID: safeGroup.id,
                                        method: .put,
                                        httpBody: httpBody) { results in
                    self.alertClosure(results, "Successfully updated \(name)")
                }
            } else {
                // Create a new group on the bridge
                httpBody[Keys.type.rawValue] = Values.room.rawValue
                httpBody[Keys.hueClass.rawValue] = Values.other.rawValue // change later once user can select the icon for the group
                DataManager.createGroup(baseURL: baseURL,
                                        httpBody: httpBody) { (Results) in
                    self.alertClosure(Results, "Successfully created group: \(name)")
                }
                
            }
        }
    }
}

extension EditGroupVC: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        rootView.tfChangeName.resignFirstResponder()
        return true
    }
}
