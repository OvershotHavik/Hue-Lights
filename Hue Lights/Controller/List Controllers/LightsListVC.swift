//
//  LightsListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/25/20.
//

import UIKit

class LightsListVC: ListController{
    weak var updateGroupDelegate : UpdateGroups?
    
    fileprivate var lightsArray : [HueModel.Light]
    fileprivate var originalLightsArray : [HueModel.Light] // used for search
    fileprivate var showingGroup: HueModel.Groups?
    fileprivate var baseURL: String
    var btnScenes: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(HueSender.scenes.rawValue, for: .normal)
        button.addTarget(self, action: #selector(scenesTapped), for: .touchUpInside)
        return button
    }()
    init(baseURL: String, lightsArray: [HueModel.Light], showingGroup: HueModel.Groups?) {
        self.baseURL = baseURL
        self.lightsArray = lightsArray
        self.showingGroup = showingGroup
        self.originalLightsArray = lightsArray
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(HueLightsCell.self, forCellReuseIdentifier: Cells.cell) // change the cell depending on which VC is using this
        tableView.delegate = self
        tableView.dataSource = self
        colorPicker.delegate = self
        if showingGroup == nil{
            setup()
        } else {
            groupsSetup()
        }
    }
    //MARK: - View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if showingGroup != nil{
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self.editGroup))
        }
        lightsArray = lightsArray.sorted(by: {$0.name < $1.name })
        self.tableView.reloadData()
        searchController.searchBar.isTranslucent = false
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        if showingGroup == nil{

            DataManager.get(baseURL: baseURL,
                            HueSender: .groups) { results in
                switch results{
                case .success(let data):
                    do {
                        let groupsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Groups>.self, from: data)
                        let groups = groupsFromBridge.compactMap{$0}
                        self.updateGroupDelegate?.updateGroupsDS(items: groups)
                    } catch let e {
                        print("Error getting Groups: \(e)")
                    }
                case .failure(let e): print(e)
                }
            }
        }
            /*
            guard let url = URL(string: baseURL + HueSender.groups.rawValue) else {return}
//            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/groups") else {return}
            print(url)
            DataManager.get(url: url) { results in
                switch results{
                case .success(let data):
                    do {
                        let groupsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Groups>.self, from: data)
                        let groups = groupsFromBridge.compactMap{$0}
                        self.updateGroupDelegate?.updateGroupsDS(items: groups)
                    } catch let e {
                        print("Error getting Groups: \(e)")
                    }
                case .failure(let e): print(e)
                }
            }
             */
//        }
    }
    //MARK: - Number of Rows in section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lightsArray.count
    }
    //MARK: - Did Select Row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let light = lightsArray[indexPath.row]
        DispatchQueue.main.async {
            let editLight = EditLightVC(baseURL: self.baseURL, light: light, showingInGroup: self.showingGroup)
            editLight.updateDelegate = self
            self.navigationController?.pushViewController(editLight, animated: true)
        }
    }
    //MARK: - Cell for row at
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        let row = lightsArray[indexPath.row]
        let rowName = row.name
        let isOn = row.state.on
        let bri = row.state.bri
        let isReachable = row.state.reachable
        let lightColor = row.state.xy
        let cellData = LightData(lightName: rowName,
                                 isOn: isOn,
                                 brightness: Float(bri),
                                 isReachable: isReachable,
                                 lightColor: ConvertColor.getRGB(xy: lightColor, bri: bri))
        cell.configureCell(LightData: cellData)
        if let tag = Int(row.id){
            cell.onSwitch.tag = tag
            cell.brightnessSlider.tag = tag
            cell.btnChangeColor.tag = tag
        }
        cell.backgroundColor = .clear
        return cell
    }
    //MARK: - Update Light Color
    override func updatLightColor(){
        guard let tempChangeColorButton = tempChangeColorButton else {return}
        tempChangeColorButton.backgroundColor = pickedColor
        let red = pickedColor.components.red
        let green = pickedColor.components.green
        let blue = pickedColor.components.blue
        let colorXY = ConvertColor.getXY(red: red, green: green, blue: blue)
        let lightID = "/\(tempChangeColorButton.tag)"
        guard let url = URL(string: baseURL + HueSender.lights.rawValue + lightID + HueSender.state.rawValue) else {return}

//        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/lights/\(lightNumber)/state") else {return}
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
extension LightsListVC: HueCellDelegate{
    func onSwitchToggled(sender: UISwitch) {
        print("Sender's Tag: \(sender.tag)")
        let lightID = "/\(sender.tag)"
        guard let url = URL(string: baseURL + HueSender.lights.rawValue + lightID + HueSender.state.rawValue) else {return}
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
        print("Brightness slider changed")
        print("Sender's Tag: \(sender.tag)")
    
        let lightID = "/\(sender.tag)"
        guard let url = URL(string: baseURL + HueSender.lights.rawValue + lightID + HueSender.state.rawValue) else {return}
//        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/lights/\(lightNumber)/state") else {return}
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
//MARK: - UI Search Bar Delegate
extension LightsListVC: UISearchBarDelegate{
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        lightsArray = originalLightsArray.sorted(by: {$0.name < $1.name})
        tableView.reloadData()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchText = searchText
        searchBar.text = searchText
        print("SearchText: \(searchText)")
        let filtered = lightsArray.filter {$0.name.contains(searchText)}
        self.lightsArray = filtered.isEmpty ? [] : filtered
        if searchText == ""{
            self.lightsArray = originalLightsArray.sorted(by: {$0.name < $1.name})
        }
        tableView.reloadData()
    }
}

//MARK: -  Edit Group
extension LightsListVC : UpdateLights{
    func updateLightsDS(items: [HueModel.Light]) {
        DispatchQueue.main.async {
            self.lightsArray = items.sorted(by: {$0.name < $1.name})
            self.tableView.reloadData()
        }
    }
    
    @objc func editGroup(){
        print("edit tapped - in light list vc")
        DataManager.get(baseURL: baseURL,
                        HueSender: .lights) { results in
            switch results{
            case .success(let data):
                do {
                    let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                    let allLightsOnBridge = lightsFromBridge.compactMap{ $0}
                    DispatchQueue.main.async {
                        //                        guard let groupDelegate = self.editingGroupDelegate else {return}
                        if let group = self.showingGroup{
                            let editGroupVC = EditGroupVC(baseURL: self.baseURL,
                                                          group: group,
                                                          allLightsOnBridge: allLightsOnBridge)
                            //                            editGroupVC.delegate = self
                            editGroupVC.updateTitleDelegate = self
                            editGroupVC.updateLightsDelegate = self
                            editGroupVC.title = "Editing \(group.name)"
                            self.navigationController?.pushViewController(editGroupVC, animated: true)
                        }
                    }
                } catch let e {
                    print("Error getting lights: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
        /*
        guard let url = URL(string: baseURL + HueSender.lights.rawValue) else {return}
        print(url)
        DataManager.get(url: url) { (results) in
            switch results{
            case .success(let data):
                do {
                    let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                    let allLightsOnBridge = lightsFromBridge.compactMap{ $0}
                    DispatchQueue.main.async {
//                        guard let groupDelegate = self.editingGroupDelegate else {return}
                        if let group = self.showingGroup{
                            let editGroupVC = EditGroupVC(baseURL: self.baseURL,
                                                          group: group,
                                                          allLightsOnBridge: allLightsOnBridge)
//                            editGroupVC.delegate = self
                            editGroupVC.updateTitleDelegate = self
                            editGroupVC.updateLightsDelegate = self
                            editGroupVC.title = "Editing \(group.name)"
                            self.navigationController?.pushViewController(editGroupVC, animated: true)
                        }
                    }
                } catch let e {
                    print("Error getting lights: \(e)")
                }
            case .failure(let e): print(e)
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

//MARK: - Group Setup
extension LightsListVC{
    func groupsSetup(){
        self.view.backgroundColor = UI.backgroundColor
        view.addSubview(btnScenes)
        view.addSubview(tableView)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            btnScenes.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: UI.verticalSpacing),
            btnScenes.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            btnScenes.heightAnchor.constraint(equalToConstant: 40),

            tableView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 50),
            tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    //MARK: - Scenes Tapped
    @objc func scenesTapped(){
        guard let group = showingGroup else {return}
        DataManager.get(baseURL: baseURL,
                        HueSender: .scenes) { results in
            switch results{
            case .success(let data):
                do {
                    let scenesFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Scenes>.self, from: data)
                    let scenes = scenesFromBridge.compactMap {$0}
                    let sceneArray = scenes.filter{$0.group == group.id}
                    
                    DispatchQueue.main.async {
                        let sceneList = SceneListVC(baseURL: self.baseURL, group: group, lightsInGroup: self.lightsArray, sceneArray: sceneArray)
//                        sceneList.delegate = self
                        sceneList.title = HueSender.scenes.rawValue
                        self.navigationController?.pushViewController(sceneList, animated: true)
                    }
                } catch let e {
                    print("Error getting scenes: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
        /*
        guard let url = URL(string: baseURL + HueSender.scenes.rawValue) else {return}
//        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/scenes") else {return}
        print(url)
        DataManager.get(url: url) {results in
            switch results{
            case .success(let data):
                do {
                    let scenesFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Scenes>.self, from: data)
                    let scenes = scenesFromBridge.compactMap {$0}
                    let sceneArray = scenes.filter{$0.group == group.id}
                    
                    DispatchQueue.main.async {
                        let sceneList = SceneListVC(baseURL: self.baseURL, group: group, lightsInGroup: self.lightsArray, sceneArray: sceneArray)
//                        sceneList.delegate = self
                        sceneList.title = HueSender.scenes.rawValue
                        self.navigationController?.pushViewController(sceneList, animated: true)
                    }
                } catch let e {
                    print("Error getting scenes: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
 */
    }
}
