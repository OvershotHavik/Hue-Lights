//
//  GroupsListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/25/20.
//

import UIKit

class GroupsListVC: ListController, BridgeInfoDelegate, editingGroup{
    var group: HueModel.Groups?
    var bridgeIP: String = ""
    var bridgeUser: String = ""
    


    private var groupsArray : [HueModel.Groups]
//    internal var hueResults : HueModel?
    
    init(groupsArray: [HueModel.Groups]) {
        self.groupsArray = groupsArray
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
        guard let delegate = delegate else {
            assertionFailure("Set the delegate")
            return
        }
        bridgeIP = delegate.bridgeIP
        bridgeUser = delegate.bridgeUser
        groupsArray = groupsArray.sorted(by: {$0.name < $1.name})
//        groupsArray = delegate.sourceItems.sorted(by: { $0.lowercased() < $1.lowercased()})
//        hueResults = delegate.hueResults
//        if let hueResults = hueResults{
//            hueGroups.append(contentsOf: hueResults.groups.values)
//        }
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
        
        group = groupsArray[indexPath.row]
        if let safeGroup = group{
            print("group: \(safeGroup.name) selected")
            let lightsInGroup = safeGroup.lights
            print("Lights in group: \(lightsInGroup)")
            // Get the light model for each light in lightsInGroup
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/lights") else {return}
            print(url)
            DataManager.get(url: url) { results in
                switch results{
                case .success(let data):
                    do {
                        let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                        let lights = lightsFromBridge.compactMap{ $0}
                        let lightsArray = lights.filter{ return lightsInGroup.contains($0.id)}
                        DispatchQueue.main.async {
                            let lightlistVC = LightsListVC(lightsArray: lightsArray, showingGroup: true)
                            lightlistVC.delegate = self
                            lightlistVC.editingGroupDelegate = self
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
        
        
        /*
         [Groups]
         Group
          - ID
          - Name
          - ...
         
         In our VC, we have a property that is our data model (var groups: [Group] = [])
         This is mutable - groups can be added, renamed, removed, etc
         If we want to sort groups in our display, groups.sorted( a.name < b.name )
         After sorting, we reload the table so that it shows things in the correct order
         Now that it's sorted in our model, we can directly work with the indices
        
        let lightIDsInGroup = groups[indexPath.row]
        */
        

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
//        groupsArray = delegate.sourceItems.sorted(by: { $0.lowercased() < $1.lowercased()})
        tableView.reloadData()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchText = searchText
        searchBar.text = searchText
        print("SearchText: \(searchText)")
//        let filtered = delegate.sourceItems.filter( {$0.contains(searchText) })
        let filtered = groupsArray.filter({$0.name.contains(searchText)})
        self.groupsArray = filtered.isEmpty ? [] : filtered
        tableView.reloadData()
    }
}

