//
//  GroupsListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/25/20.
//

import UIKit

class GroupsListVC: ListController, ListSelectionControllerDelegate{
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
                                     brightness: Float(group.action.bri),
                                     isReachable: true,
                                     lightColor: ConvertColor.getRGB(xy: group.action.xy, bri: group.action.bri))
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
        guard let delegate = delegate else {
            assertionFailure("Set the delegate")
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        print("group: \(groupsArray[indexPath.row]) selected")
        let groupName = groupsArray[indexPath.row]
        var lightsInGroup = [String]()
        for x in hueGroups{
            if x.name == groupName{
                lightsInGroup.append(contentsOf: x.lights)
            }
        }
        print("Lights in group: \(lightsInGroup)")
//        let hueLights = [HueModel.Light]()
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)") else {return}
        
        
        
//        need to get the light info for the lights that are in the group, and then send that info over to a light list VC so then the lights that are in that group can be modified individually, and eventually added/removed
        
        
        
        DataManager.get(url: url) { (results) in
            switch results{
            case .success(let data):
                do {
                    self.hueResults = []
                    self.sourceItems = []
                    let resultsFromBrdige = try JSONDecoder().decode(HueModel.self, from: data)
                    self.hueResults.append(resultsFromBrdige)
                        for light in resultsFromBrdige.lights{
                            if lightsInGroup.contains(light.key){
                                self.sourceItems.append(light.value.name)
                            }
                        }
                        DispatchQueue.main.async {
                            let lightlistVC = LightsListVC()
                            lightlistVC.delegate = self
                            lightlistVC.title = self.groupsArray[indexPath.row]
                            self.navigationController?.pushViewController(lightlistVC, animated: true)
                        }


                    
                } catch let e {
                    print("Error: \(e)")
                }
            case .failure(let e): print("Error getting info: \(e)")
            }
        }
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
