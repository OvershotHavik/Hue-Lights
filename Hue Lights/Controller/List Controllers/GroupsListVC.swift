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
    //MARK: - View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        colorPicker.delegate = self
        tableView.register(HueLightsCell.self, forCellReuseIdentifier: Cells.cell)
        tableView.delegate = self
        tableView.dataSource = self
        searchController.searchBar.isTranslucent = false
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addGroup))
        setup()
    }
    @objc func addGroup(){
        print("Add group tapped")
        DataManager.get(baseURL: baseURL, HueSender: .lights) { results in
            switch results{
            case .success(let data):
                do {
                    let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                    let lights = lightsFromBridge.compactMap{ $0}
                    for light in lights{
                        print("Light id: \(light.id) - \(light.name)")
                    }
                    DispatchQueue.main.async {
                        let createGroupVC = EditGroupVC(baseURL: self.baseURL,
                                                        group: nil,
                                                        allLightsOnBridge: lights)
                        createGroupVC.title = "Create a new Group"
                        self.navigationController?.pushViewController(createGroupVC, animated: true)
                    }
                } catch let e {
                    print("Error getting lights: \(e)")
                }
            case .failure(let e): print(e)
            }
        }

    }
    //MARK: - View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        groupsArray = groupsArray.sorted(by: {$0.name < $1.name})
        self.tableView.reloadData()
    }
//MARK: - Number of rows in section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupsArray.count
    }
    //MARK: - Cell For Row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        let group = groupsArray[indexPath.row]
        cell.configureGroupCell(group: group)
        if let tag = Int(group.id){
            cell.onSwitch.tag = tag
            cell.brightnessSlider.tag = tag
            cell.btnChangeColor.tag = tag
        }
        cell.backgroundColor = .clear
        return cell
    }
    //MARK: - Did Select Row
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
    }
    //MARK: - Sent Lights List To VC
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
                        let lightsInGroupVC = LightsInGroupVC(baseURL: self.baseURL,
                                                       lightsArray: lightsArray,
                                                       group: group)
                        lightsInGroupVC.updateGroupDelegate = self
                        lightsInGroupVC.title = group.name
                        self.navigationController?.pushViewController(lightsInGroupVC, animated: true)
                    }
                } catch let e {
                    print("Error getting lights: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
    }
    //MARK: - Update Group DataSource
    func updateGroupsDS(items: [HueModel.Groups]) {
        DispatchQueue.main.async {
            self.groupsArray = items.sorted(by: {$0.name < $1.name})
            self.tableView.reloadData()
        }
    }
    
    //MARK: - Update Light Color
    override func updateLightColor(){
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
    }
    //MARK: - Change Light Color
    func changeLightColor(sender: UIButton) {
        print("change light color tapped")
        if let safeColor = sender.backgroundColor{
            pickedColor = safeColor
        }
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

