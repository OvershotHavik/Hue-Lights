//
//  GroupsListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/25/20.
//

import UIKit

class GroupsListVC: ListController, ListSelectionControllerDelegate, editingGroup{
    var groupName: String = ""
    
    var groupNumber: String = ""
    
    var sourceItems: [String] = []
    var bridgeIP: String = ""
    var bridgeUser: String = ""
    

    private var groupsArray = [String]()
    private var hueGroups = [HueModel.Groups]()
    internal var hueResults = [HueModel]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let delegate = delegate else {
            assertionFailure("Set the delegate")
            return
        }
        bridgeIP = delegate.bridgeIP
        bridgeUser = delegate.bridgeUser
        groupsArray = delegate.sourceItems.sorted(by: { $0.lowercased() < $1.lowercased()})
        hueResults = delegate.hueResults
        for x in hueResults{
            hueGroups.append(contentsOf: x.groups.values)
        }
        self.tableView.reloadData()
        searchController.searchBar.delegate = self
        setup()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupsArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        let rowName = groupsArray[indexPath.row]
        let filtered = hueGroups.filter({$0.name == rowName})
        
        for group in filtered{
            let cellData = LightData(lightName: group.name,
                                     isOn: group.state.all_on,
                                     brightness: Float(group.action.bri ?? 0),
                                     isReachable: true,
                                     lightColor: ConvertColor.getRGB(xy: group.action.xy, bri: group.action.bri ?? 0))
            cell.configureCell(LightData: cellData)
            for x in hueResults{
                for i in x.groups{
                    if i.value.name == group.name{
                        if let tag = Int(i.key){
                            cell.onSwitch.tag = tag
                            cell.brightnessSlider.tag = tag
                            cell.btnChangeColor.tag = tag
    //                        print("tag: \(onSwitch.tag)")
                        }
                    }
                }
            }
        }
        cell.backgroundColor = .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        groupName = groupsArray[indexPath.row]
        print("group: \(String(describing: groupName)) selected")
        var lightsInGroup = [String]()
        for x in hueGroups{
            if x.name == groupName{
                lightsInGroup.append(contentsOf: x.lights)
            }
        }
        print("Lights in group: \(lightsInGroup)")
        self.sourceItems = []
        for x in hueResults{
            for light in x.lights{
                if lightsInGroup.contains(light.key){
                    self.sourceItems.append(light.value.name)
                }
            }
            for group in x.groups{
                if group.value.name == groupName{
                    self.groupNumber = group.key
                }
            }
        }
        DispatchQueue.main.async {
            let lightlistVC = LightsListVC()
            lightlistVC.delegate = self
            lightlistVC.editingGroupDelegate = self
            lightlistVC.title = self.groupsArray[indexPath.row]
            self.navigationController?.pushViewController(lightlistVC, animated: true)
        }
    }

    
    
    //MARK: - Update Light Color
    override func updatLightColor(){
        guard let tempChangeColorButton = tempChangeColorButton else {return}
        guard let delegate = delegate else { return}
        tempChangeColorButton.backgroundColor = pickedColor
        let red = pickedColor.components.red
        let green = pickedColor.components.green
        let blue = pickedColor.components.blue
        let colorXY = ConvertColor.getXY(red: red, green: green, blue: blue)
        let lightNumber = tempChangeColorButton.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/groups/\(lightNumber)/action") else {return}
        print(url)
        let httpBody = [
            "xy": colorXY,
        ]
        DataManager.put(url: url, httpBody: httpBody)
    }
}
//MARK: - Hue Cell Delegate
extension GroupsListVC: HueCellDelegate{
    func onSwitchToggled(sender: UISwitch) {
        guard let delegate = delegate else { return}
        print("Sender's Tag: \(sender.tag)")
        let lightNumber = sender.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/groups/\(lightNumber)/action") else {return}
        print(url)
        let httpBody = [
            "on": sender.isOn,
        ]
        DataManager.put(url: url, httpBody: httpBody)
    }
    
    func brightnessSliderChanged(sender: UISlider) {
        guard let delegate = delegate else { return}
        print("Brightness slider changed")
        print("Sender's Tag: \(sender.tag)")
        
        let lightNumber = sender.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/groups/\(lightNumber)/action") else {return}
        print(url)
        let httpBody = [
            "bri": Int(sender.value),
        ]
        DataManager.put(url: url, httpBody: httpBody)
        
    }
    func changeLightColor(sender: UIButton) {
        print("change light color tapped")
        selectColor()
        tempChangeColorButton = sender
    }
    

}

//MARK: - UISearch Bar Delegate
extension GroupsListVC: UISearchBarDelegate{
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        guard let delegate = delegate else {
            assertionFailure("Set the delegate bitch")
            return
        }
        groupsArray = delegate.sourceItems.sorted(by: { $0.lowercased() < $1.lowercased()})
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
        self.groupsArray = filtered.isEmpty ? [] : filtered
        tableView.reloadData()
    }
}

