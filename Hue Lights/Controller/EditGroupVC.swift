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

class EditGroupVC: UIViewController, ListSelectionControllerDelegate{
    var hueResults = [HueModel]()
    var bridgeIP = String()
    var bridgeUser = String()
    weak var delegate : ListSelectionControllerDelegate?
    weak var updateTitleDelegate : UpdateTitle?
    weak var updateDelegate : UpdatedHueResults?
    fileprivate var rootView : EditItemView!
    fileprivate var lightNameInGroup = [String]()
    fileprivate var lightNumbersInGroup = [String()]
    internal var sourceItems = [String]()
    fileprivate var groupName : String
    fileprivate var groupNumber : String
    init(groupName: String, groupNumber: String) {
        self.groupName = groupName
        self.groupNumber = groupNumber
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        guard let delegate = delegate  else {
            print("setup delegate for EditGroupVC")
            return
        }
        rootView = EditItemView(itemName: groupName)
        bridgeIP = delegate.bridgeIP
        bridgeUser = delegate.bridgeUser
        hueResults = delegate.hueResults
        self.view = rootView
        rootView.updateGroupDelegate = self
        updateListOnView()
        lightNumbersInGroup = getNumberFromName(lightNames: lightNameInGroup)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        updateTitleDelegate?.updateTitle(newTitle: groupName)
        updateLightListInGroup()
    }
    
    //MARK: - Update Light List on rootView
    func updateListOnView(){
        lightNameInGroup = getNamesFromNumbers()
        var text = String()
        for light in lightNameInGroup{
            text += "\(light)\n"
        }
        rootView.updateLabel(text: text)
    }

    //MARK: - Update Light List In Group
    func updateLightListInGroup(){
        //for sending back to the previous VC to update the list when lights are changed
        guard let delegate = delegate  else {return}
        print("Get Info")
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)") else {return}
        print(url)
        
        DataManager.get(url: url) { (results) in
            switch results{
            case .success(let data):
                do {
                    var tempHueResults = [HueModel]()
                    let resultsFromBrdige = try JSONDecoder().decode(HueModel.self, from: data)
                    tempHueResults.append(resultsFromBrdige)
                    self.updateDelegate?.getUpdatedHueResults(hueResults: tempHueResults)
                } catch let e{
                    print("Error getting info in edit group vc \(e)")
                }
            case .failure(let e):
                print("Error getting info in edit group vc \(e)")
            }
        }
    }
 
}
//MARK: - Update Group Delegate
extension EditGroupVC: UpdateItem, SelectedItems{
    func deleteTapped(name: String) {
        
    }
    
    func setSelectedItems(items: [String], ID: String) {
        lightNameInGroup = items.sorted { $0 < $1}
        var text = String()
        for light in lightNameInGroup{
            text += "\(light)\n"
        }
        rootView.updateLabel(text: text)
    }
    
    
    
    //MARK: - Get Names From Numbers
    func getNamesFromNumbers() -> [String]{
        guard let delegate = delegate else {return []}
        var lightNumbers = [String]()
        var lightNames = [String]()
        var lightsInGroupsAlready = [String]()
        for x in delegate.hueResults{
            for group in x.groups{
                if group.value.name == groupName{
                    for light in group.value.lights{
                        lightNumbers.append(light) // get number of the lights that are currently in the group
                    }
                }
                lightsInGroupsAlready.append(contentsOf: group.value.lights)
            }
            print("Lights in groups already: \(lightsInGroupsAlready.sorted())")
            for light in x.lights{
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
        return lightNames
    }
    //MARK: - Get Numbers from Names
    func getNumberFromName(lightNames: [String]) -> [String]{
        guard let delegate = delegate else {return []}
        var lightNumbers = [String]()
        for x in delegate.hueResults{
            for name in lightNames{
                for light in x.lights{
                    if light.value.name == name{
                        lightNumbers.append(light.key)
                    }
                }
            }
        }
        return lightNumbers
    }
    
    
    //MARK: - Take user to edit lights in the group
    func editList() {
        DispatchQueue.main.async {
            let lightList = ModifyGroupList(limit: 9999, selectedItems: self.lightNameInGroup)
            lightList.delegate = self
            lightList.selectedItemsDelegate = self
            self.navigationController?.pushViewController(lightList, animated: true)
        }
    }
    //MARK: - Save Tapped
    func saveTapped(name: String) {
        groupName = name
        self.lightNumbersInGroup = getNumberFromName(lightNames: self.lightNameInGroup)
        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/groups/\(groupNumber)") else {return}
        print(url)
        var httpBody = [String: Any]()
        httpBody["name"] = name
        httpBody["lights"] = self.lightNumbersInGroup
        DataManager.sendRequest(method: .put, url: url, httpBody: httpBody) { result in
            DispatchQueue.main.async {
                switch result{
                case .success(let response):
                    if response.contains("success"){
                        Alert.showBasic(title: "Saved!", message: "Successfully updated \(self.groupName)", vc: self)
                    } else {
                        Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                    }
                case .failure(let e): print("Error occured: \(e)")
                }
            }
        }
    }
}
