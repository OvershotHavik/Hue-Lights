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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        colorPicker.delegate = self
        tableView.register(HueLightsCell.self, forCellReuseIdentifier: Cells.cell) // change the cell depending on which VC is using this
        tableView.delegate = self
        tableView.dataSource = self
        searchController.searchBar.isTranslucent = false
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
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
            let lightlistVC = LightsListVC(showingGroup: true)
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
//MARK: - Hue Cell Delegate
extension GroupsListVC: HueCellDelegate{
    func onSwitchToggled(sender: UISwitch) {
        guard let delegate = delegate else { return}
        print("Sender's Tag: \(sender.tag)")
        let groupNumber = sender.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/groups/\(groupNumber)/action") else {return}
        print(url)
        let httpBody = [
            "on": sender.isOn,
        ]
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
    //MARK: - Brightness Slider Changed
    func brightnessSliderChanged(sender: UISlider) {
        // Will need to find a way to limit the commands to the bridge to be one command per second, otherwise an error can come up if it tries to process too many (moving the slider back and forth quickly)
        guard let delegate = delegate else { return}
        print("Brightness slider changed")
        print("Sender's Tag: \(sender.tag)")
        
        let lightNumber = sender.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/groups/\(lightNumber)/action") else {return}
        print(url)
        let httpBody = [
            "bri": Int(sender.value),
        ]
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

