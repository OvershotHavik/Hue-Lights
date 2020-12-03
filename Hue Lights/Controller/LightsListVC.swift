//
//  LightsListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/25/20.
//

import UIKit

protocol editingGroup: class{
    var groupName : String {get}
    var groupNumber: String {get}
}

class LightsListVC: ListController, ListSelectionControllerDelegate{
    weak var editingGroupDelegate: editingGroup?
    var sourceItems = [String]()
    var bridgeIP = String()
    var bridgeUser = String()
    
    private var lightsArray = [String]()
    private var hueLights = [HueModel.Light]()
    internal var hueResults = [HueModel]()
//    fileprivate var groupName : String?
//    fileprivate var groupNumber : String?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let delegate = delegate else {
            assertionFailure("Set the delegate")
            return
        }
        bridgeIP = delegate.bridgeIP
        bridgeUser = delegate.bridgeUser
        
        if self.title != UI.lights{
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self.editGroup))
        }
        lightsArray = delegate.sourceItems.sorted(by: { $0.lowercased() < $1.lowercased()})
        hueResults = delegate.hueResults
        for x in hueResults{
            hueLights.append(contentsOf: x.lights.values)
        }
        self.tableView.reloadData()
        searchController.searchBar.delegate = self
        setup()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lightsArray.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        DispatchQueue.main.async {
            let editLight = EditLightVC(lightName: self.lightsArray[indexPath.row])
            editLight.delegate = self
            self.navigationController?.pushViewController(editLight, animated: true)
        }
        print("Take user to modify the individual light, change name, add to gorup, etc...")
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        let rowName = lightsArray[indexPath.row]
        let filtered = hueLights.filter({$0.name == rowName})
        for light in filtered{
            let reachable = light.state.reachable
            let cellData = LightData(lightName: light.name,
                                     isOn: light.state.on,
                                     brightness: Float(light.state.bri),
                                     isReachable: reachable,
                                     lightColor: ConvertColor.getRGB(xy: light.state.xy, bri: light.state.bri))
            cell.configureCell(LightData: cellData)
            for x in hueResults{
                for i in x.lights{
                    if i.value.name == light.name{
                        if let tag = Int(i.key){
                            cell.onSwitch.tag = tag
                            cell.brightnessSlider.tag = tag
                            cell.btnChangeColor.tag = tag
                        }
                    }
                }
            }
            cell.backgroundColor = .clear
        }
        return cell
    }
    
    override func updatLightColor(){
        guard let tempChangeColorButton = tempChangeColorButton else {return}
        guard let delegate = delegate else { return}
        tempChangeColorButton.backgroundColor = pickedColor
        let red = pickedColor.components.red
        let green = pickedColor.components.green
        let blue = pickedColor.components.blue
        let colorXY = ConvertColor.getXY(red: red, green: green, blue: blue)
        let lightNumber = tempChangeColorButton.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/lights/\(lightNumber)/state") else {return}
        print(url)
        let httpBody = [
            "xy": colorXY,
        ]
        DataManager.put(url: url, httpBody: httpBody) { result in
            DispatchQueue.main.async {
                switch result{
                case .success(let response):
                    if response.contains("success"){
                        //don't display an erlt if successful
                    } else {
                        Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                    }
                case .failure(let e): print("Error occured: \(e)")
                }
            }
        }
        
    }
}
//MARK: - Hue Cell Delegate
extension LightsListVC: HueCellDelegate{
    func onSwitchToggled(sender: UISwitch) {
        guard let delegate = delegate else { return}
        print("Sender's Tag: \(sender.tag)")
        let lightNumber = sender.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/lights/\(lightNumber)/state") else {return}
        print(url)
        let httpBody = [
            "on": sender.isOn,
        ]
        DataManager.put(url: url, httpBody: httpBody) { result in
            DispatchQueue.main.async {
                switch result{
                case .success(let response):
                    if response.contains("success"){
                        //don't display an erlt if successful
                    } else {
                        Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                    }
                case .failure(let e): print("Error occured: \(e)")
                }
            }
        }
        
    }
    
    func brightnessSliderChanged(sender: UISlider) {
        guard let delegate = delegate else { return}
        print("Brightness slider changed")
        print("Sender's Tag: \(sender.tag)")
        
        let lightNumber = sender.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/lights/\(lightNumber)/state") else {return}
        print(url)
        let httpBody = [
            "bri": Int(sender.value),
        ]
        DataManager.put(url: url, httpBody: httpBody) { result in
            DispatchQueue.main.async {
                switch result{
                case .success(let response):
                    if response.contains("success"){
                        //don't display an erlt if successful
                    } else {
                        Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                    }
                case .failure(let e): print("Error occured: \(e)")
                }
            }
        }
    }
    func changeLightColor(sender: UIButton) {
        print("change light color tapped")
        selectColor()
        tempChangeColorButton = sender
    }

}
//MARK: - UI Search Bar Delegate
extension LightsListVC: UISearchBarDelegate{
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        guard let delegate = delegate else {
            assertionFailure("Set the delegate bitch")
            return
        }
        lightsArray = delegate.sourceItems.sorted(by: { $0.lowercased() < $1.lowercased()})
        tableView.reloadData()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchText = searchText
        searchBar.text = searchText
        guard let delegate = delegate else {
            assertionFailure("Set the delegate")
            return
        }
        print("SearchText: \(searchText)")
        let filtered = delegate.sourceItems.filter( {$0.contains(searchText) })
        self.lightsArray = filtered.isEmpty ? [] : filtered
        tableView.reloadData()
    }
}


extension LightsListVC{
    //MARK: -  Edit Group
    @objc func editGroup(){
        print("edit tapped - in light list vc")
        DispatchQueue.main.async {
            guard let groupDelegate = self.editingGroupDelegate else {return}
             let safeGroupName = groupDelegate.groupName
               let safeGroupNumber = groupDelegate.groupNumber
                let editGroupVC = EditGroupVC(groupName: safeGroupName, groupNumber: safeGroupNumber)
                editGroupVC.delegate = self
//                editGroupVC.updateTitleDelegate = self
                editGroupVC.updateDelegate = self
                editGroupVC.title = "Editing \(safeGroupName)"
                self.navigationController?.pushViewController(editGroupVC, animated: true)
            
        }
    }
}
//MARK: - Update Hue Results to update the list
extension LightsListVC: UpdatedHueResults{
    func getUpdatedHueResults(hueResults: [HueModel]) {
        print("update the list...")
        /*
        self.hueResults = hueResults
//        self.sourceItems = []
        var lightsInGroup = [String]()
//        for x in hueGroups{
//            if x.name == groupName{
//                lightsInGroup.append(contentsOf: x.lights)
//            }
//        }
        print("Lights in group: \(lightsInGroup)")
        self.sourceItems = []
        for x in hueResults{
            for light in x.lights{
                if lightsInGroup.contains(light.key){
                    self.sourceItems.append(light.value.name)
                }
            }
        }
        
        
        
        var lightsInGroup = [String]()
        for x in self.hueResults{
            for group in x.groups{
                if group.value.name == self.groupName{
                    var lightsInGroup = group.value.lights
                    
//                    sourceItems = group.value.lights
//                    lightsArray = delegate.sourceItems.sorted(by: { $0.lowercased() < $1.lowercased()})
                    lightsArray =
//                    hueResults = delegate.hueResults
//                    hueLights.append(contentsOf: group.value.lights)
                    self.tableView.reloadData()
                }
            }
        }
         */
    }
    
    
    

}

//MARK: - Update Title
extension LightsListVC: UpdateTitle{
    func updateTitle(newTitle: String) {
        self.title = newTitle
    }
}
