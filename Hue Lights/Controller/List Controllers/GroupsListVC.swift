//
//  GroupsListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/25/20.
//

import UIKit

class GroupsListVC: ListController, UpdateGroups{
    fileprivate var groupsArray : [HueModel.Groups]
    fileprivate var originalGroupsArray : [HueModel.Groups]
    fileprivate var baseURL : String
    init(baseURL: String, groupsArray: [HueModel.Groups]) {
        self.baseURL = baseURL
        self.groupsArray = groupsArray
        self.originalGroupsArray = groupsArray
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        groupsArray = groupsArray.sorted(by: {$0.name < $1.name})
        self.tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupsArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        let row = groupsArray[indexPath.row]
        let name = row.name
        let isOn = row.state.all_on
        let bri = row.action.bri
        let color = row.action.xy
        let cellData = LightData(lightName: name,
                                 isOn: isOn,
                                 brightness: Float(bri ?? 0),
                                 isReachable: true,
                                 lightColor: ConvertColor.getRGB(xy: color, bri: bri ?? 0))
        cell.configureCell(LightData: cellData)
        if let tag = Int(row.id){
            cell.onSwitch.tag = tag
            cell.brightnessSlider.tag = tag
            cell.btnChangeColor.tag = tag
        }
        cell.backgroundColor = .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let group = groupsArray[indexPath.row]
        print("group: \(group.name) selected")
        //get updatedLights in group, then get the models for those lights to send to the light vc
        DataManager.get(baseURL: baseURL,
                        HueSender: .groups) { results in
            switch results{
            case .success(let data):
                do {
                    let groupsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Groups>.self, from: data)
                    let groups = groupsFromBridge.compactMap{$0}
                    if let updatedGroup = groups.filter({$0 == group}).first{
                        self.sendLightsListToVC(lightsInGroup: updatedGroup.lights, group: updatedGroup)
                    }
                } catch let e {
                    print("Error getting Groups: \(e)")
                }

            case .failure(let e): print(e)
                
            }
        }

        /*
        guard let url = URL(string: baseURL + HueSender.lights.rawValue) else {return}
        //            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/lights") else {return}
        print(url)
        DataManager.get(url: url) { results in
            switch results{
            case .success(let data):
                do {
                    let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                    let lights = lightsFromBridge.compactMap{ $0}
                    let lightsArray = lights.filter{ return lightsInGroup.contains($0.id)}
                    DispatchQueue.main.async {
                        let lightlistVC = LightsListVC(baseURL: self.baseURL,
                                                       lightsArray: lightsArray,
                                                       showingGroup: group)
                        lightlistVC.updateGroupDelegate = self
                        lightlistVC.title = HueSender.lights.rawValue
                        self.navigationController?.pushViewController(lightlistVC, animated: true)
                    }
                } catch let e {
                    print("Error getting lights: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
        */
    }
    func sendLightsListToVC(lightsInGroup: [String], group: HueModel.Groups){
        print("Lights in group: \(lightsInGroup)")
        // Get the light model for each light in lightsInGroup
        DataManager.get(baseURL: baseURL,
                        HueSender: .lights) { results in
            switch results{
            case .success(let data):
                do {
                    let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                    let lights = lightsFromBridge.compactMap{ $0}
                    let lightsArray = lights.filter{ return lightsInGroup.contains($0.id)}
                    DispatchQueue.main.async {
                        let lightlistVC = LightsListVC(baseURL: self.baseURL,
                                                       lightsArray: lightsArray,
                                                       showingGroup: group)
                        lightlistVC.updateGroupDelegate = self
                        lightlistVC.title = HueSender.lights.rawValue
                        self.navigationController?.pushViewController(lightlistVC, animated: true)
                    }
                } catch let e {
                    print("Error getting lights: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
    }
    func updateGroupsDS(items: [HueModel.Groups]) {
        DispatchQueue.main.async {
            self.groupsArray = items.sorted(by: {$0.name < $1.name})
            self.tableView.reloadData()
        }
    }
    
    
    //MARK: - Update Light Color
    override func updatLightColor(){
        guard let tempChangeColorButton = tempChangeColorButton else {return}
        tempChangeColorButton.backgroundColor = pickedColor
        let red = pickedColor.components.red
        let green = pickedColor.components.green
        let blue = pickedColor.components.blue
        let colorXY = ConvertColor.getXY(red: red,
                                         green: green,
                                         blue: blue)
        let groupID = String(tempChangeColorButton.tag)

        let httpBody = ["xy": colorXY]
        DataManager.updateGroup(baseURL: baseURL,
                                groupID: groupID,
                                method: .put,
                                httpBody: httpBody,
                                completionHandler: self.noAlertOnSuccessClosure)
        /*
        guard let url = URL(string: baseURL + HueSender.groups.rawValue + groupID + HueSender.action.rawValue) else {return}
//        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/groups/\(lightNumber)/action") else {return}
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
        */
    }
}
//MARK: - Hue Cell Delegate
extension GroupsListVC: HueCellDelegate{
    func onSwitchToggled(sender: UISwitch) {
        print("Sender's Tag: \(sender.tag)")
        let groupID = String(sender.tag)
        let httpBody = ["on": sender.isOn]
        DataManager.updateGroup(baseURL: baseURL,
                                groupID: groupID,
                                method: .put,
                                httpBody: httpBody,
                                completionHandler: noAlertOnSuccessClosure)
        
        /*
        let groupID = "/\(sender.tag)"
        guard let url = URL(string: baseURL + HueSender.groups.rawValue + groupID + HueSender.action.rawValue) else {return}
//        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/groups/\(groupNumber)/action") else {return}
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
        */
    }
    //MARK: - Brightness Slider Changed
    func brightnessSliderChanged(sender: UISlider) {
        // Will need to find a way to limit the commands to the bridge to be one command per second, otherwise an error can come up if it tries to process too many (moving the slider back and forth quickly)
        print("Brightness slider changed")
        print("Sender's Tag: \(sender.tag)")
        
        let groupID = String(sender.tag)
        let httpBody = ["bri": Int(sender.value)]
        DataManager.updateGroup(baseURL: baseURL,
                                groupID: groupID,
                                method: .put,
                                httpBody: httpBody,
                                completionHandler: noAlertOnSuccessClosure)
        /*
        guard let url = URL(string: baseURL + HueSender.groups.rawValue + groupID + HueSender.action.rawValue) else {return}
//        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/groups/\(lightNumber)/action") else {return}
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
        */
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
        DispatchQueue.main.async {
            self.groupsArray = self.originalGroupsArray.sorted(by: {$0.name < $1.name})
            self.tableView.reloadData()
        }

    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchText = searchText
        searchBar.text = searchText
        print("SearchText: \(searchText)")
        DispatchQueue.main.async {
            let filtered = self.groupsArray.filter({$0.name.contains(searchText)})
            self.groupsArray = filtered.isEmpty ? [] : filtered
            if searchText == ""{
                self.groupsArray = self.originalGroupsArray.sorted(by: {$0.name < $1.name})
            }
            self.tableView.reloadData()
        }
    }
}

