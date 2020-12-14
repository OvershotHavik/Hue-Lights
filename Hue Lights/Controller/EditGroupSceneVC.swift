//
//  EditSceneVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/6/20.
//

import UIKit

class EditGroupSceneVC: UIViewController, BridgeInfoDelegate{
    var bridgeIP = String()
    var bridgeUser = String()
    

    weak var delegate: BridgeInfoDelegate?
    weak var updateDelegate : UpdateScenes?
    fileprivate var rootView : EditSceneView!
    fileprivate var subView : LightsListVC!
    fileprivate var sceneName: String
    fileprivate var groupLights = [HueModel.Light]()
    fileprivate var sceneID : String
    fileprivate var sceneLights = [String : HueModel.Lightstates]()
    fileprivate var tempChangeColorButton : UIButton?
    fileprivate var group : HueModel.Groups
    fileprivate var lightsInGroup : [HueModel.Light]
    init(sceneName: String, sceneID: String, group: HueModel.Groups, lightsInGroup: [HueModel.Light]) {
        self.sceneName = sceneName
        self.sceneID = sceneID
        self.group = group
        self.lightsInGroup = lightsInGroup
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func loadView() {
        super.loadView()
        rootView = EditSceneView(sceneName: sceneName)
        rootView.updateSceneDelegate = self
        subView = LightsListVC(lightsArray: lightsInGroup, showingGroup: false)
        subView.delegate = self
        addChildVC()
        self.view = rootView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Edit Scene"
        guard let delegate = delegate else {
            assertionFailure("Set the delegate")
            return
        }
        bridgeIP = delegate.bridgeIP
        bridgeUser = delegate.bridgeUser
        lightsInGroup = lightsInGroup.sorted(by: {$0.name < $1.name})
        subView.tableView.reloadData()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        getSceneLightStates()
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        updateSceneListVC()
    }
    
    func updateSceneListVC(){
        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/scenes") else {return}
        print(url)
        DataManager.get(url: url) { results in
            switch results{
            case .success(let data):
                do {
                    let scenesFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Scenes>.self, from: data)
                    let scenes = scenesFromBridge.compactMap {$0}
                    let sceneArray = scenes.filter{$0.group == self.group.id}
                    self.updateDelegate?.updateScenesDS(items: sceneArray)
                } catch let e {
                    print("Error getting scenes: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
    }
    //MARK: - Add Child VC - subView - Light List
    func addChildVC(){
        addChild(subView)
        rootView.addSubview(subView.view)
        subView.view.backgroundColor = .clear
        subView.didMove(toParent: self)
        subView.tableView.dataSource = self
        subView.colorPicker.delegate = self
        
        subView.view.translatesAutoresizingMaskIntoConstraints = false
        let safeArea = rootView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            subView.view.topAnchor.constraint(equalTo: rootView.tfChangeName.bottomAnchor, constant: UI.verticalSpacing),
            subView.view.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            subView.view.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            subView.view.bottomAnchor.constraint(equalTo: rootView.btnSave.topAnchor, constant: -UI.verticalSpacing)
        ])
    }
}


//MARK: - SubVIew Tableview dataSource
extension EditGroupSceneVC: HueCellDelegate, UITableViewDataSource{
    //change the light list VC's cell's to match what the scene shows, not what is currently on the light
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        let light = lightsInGroup[indexPath.row]
        let config = sceneLights[light.id]
        var lightBri = 1
        var lightXY = [Double]()
        var lightOn = Bool()
        if let safeBRI = config?.bri{
            lightBri = safeBRI
        }
        if let safeXY = config?.xy{
            lightXY = safeXY
        }
        if let safeLightOn = config?.on{
            lightOn = safeLightOn
        }
        if let tag = Int(light.id){
            cell.onSwitch.tag = tag
            cell.brightnessSlider.tag = tag
            cell.btnChangeColor.tag = tag
        }
        let cellData = LightData(lightName: light.name,
                                 isOn: lightOn,
                                 brightness: Float(lightBri),
                                 isReachable: true,
                                 lightColor: ConvertColor.getRGB(xy: lightXY, bri: lightBri))
        cell.configureCell(LightData: cellData)
        cell.backgroundColor = .clear
        return cell
    }
    //MARK: - Number of rows
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lightsInGroup.count
    }
    
    //MARK: - On Switch Toggled
    func onSwitchToggled(sender: UISwitch) {
        print("sender tag: \(sender.tag)")
        let lightID = String(sender.tag)
        let light = sceneLights[lightID]
        if let currentBRI = light?.bri,
           let currentXY = light?.xy{
            let lightStateData = HueModel.Lightstates(on: sender.isOn,
                                                      bri: currentBRI,
                                                      xy: currentXY)
            sceneLights[lightID] = lightStateData
            
            //Apply to light
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/lights/\(lightID)/state") else {return}
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
    }
    //MARK: - Brightness Slider Changed
    func brightnessSliderChanged(sender: UISlider) {
        let lightID = String(sender.tag)
        let light = sceneLights[lightID] // used to verify values below
        if let currentIsOn = light?.on,
           let currentXY = light?.xy{
            let lightStateData = HueModel.Lightstates(on: currentIsOn,
                                                      bri: Int(sender.value),
                                                      xy: currentXY)
            sceneLights[lightID] = lightStateData
            
            //Apply to light
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/lights/\(lightID)/state") else {return}
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
    }
    //MARK: - Change Light Color tapped
    func changeLightColor(sender: UIButton) {
        print("sender tag: \(sender.tag)")
        print("change light color tapped")
        if let safeColor = sender.backgroundColor{
            subView.pickedColor = safeColor
        }
        subView.selectColor()
        tempChangeColorButton = sender
    }
    //MARK: - Update Light Color once picked from color picker
    func updatLightColor(){
        guard let tempChangeColorButton = tempChangeColorButton else {return}
        tempChangeColorButton.backgroundColor = subView.pickedColor
        let lightID = String(tempChangeColorButton.tag)
//        print("temp chagne button tag: \(tempChangeColorButton.tag)")
        let red = subView.pickedColor.components.red
        let green = subView.pickedColor.components.green
        let blue = subView.pickedColor.components.blue
        let colorXY = ConvertColor.getXY(red: red, green: green, blue: blue)
        let light = sceneLights[lightID] // used to verify values exist below
        if let currentBri = light?.bri,
           let currentOn = light?.on{
            let lightStateData = HueModel.Lightstates(on: currentOn,
                                                      bri: currentBri,
                                                      xy: colorXY)
            sceneLights[lightID] = lightStateData
            
            //Apply to light
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/lights/\(lightID)/state") else {return}
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
    //MARK: - Get Scene Light State From Bridge
    func getSceneLightStates(){
        if sceneID == Constants.newScene.rawValue{
            print("New scene, adding lights listed into scenelights")
             for light in lightsInGroup{
                 let lightStateData = HueModel.Lightstates(on: true, bri: 150, xy: [])
                 sceneLights[light.id] = lightStateData
             }
        } else {
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/scenes/\(sceneID)") else {return}
            print(url)
            DataManager.get(url: url) { (results) in
                switch results{
                case.success(let data):
                    do {
                        print("before json string")
                        if let JSONString = String(data: data, encoding: String.Encoding.utf8){
                            print(JSONString)
                        }
                        
                        let resultsFromBridge = try JSONDecoder().decode(HueModel.IndividualScene.self, from: data)
                        if let safeLightStates = resultsFromBridge.lightstates{
                            self.sceneLights = safeLightStates
                            self.applyLightStatesToLights()
                        }
                        for light in self.sceneLights{
                            print("light key: \(light.key), light xy: \(light.value.xy ?? [0,0])")
                        }
                    } catch let e{
                        print(e)
                    }
                case .failure(let e): print("error: \(e)")
                }
            }
        }
    }
    //MARK: - Apply Light States To Lights
    func applyLightStatesToLights(){
        guard let delegate = delegate else {return}
        for light in sceneLights{
            guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/lights/\(light.key)/state") else {return}
            print(url)
            var httpBody = [String: Any]()
            httpBody["on"] = light.value.on
            httpBody["bri"] = Int(light.value.bri)
            if let safeXY = light.value.xy{
                httpBody["xy"] = safeXY
            }
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
}
//MARK: - Color Picker Delegate
extension EditGroupSceneVC: UIColorPickerViewControllerDelegate{
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        subView.pickedColor = viewController.selectedColor
        updatLightColor()
    }
}

//MARK: - Update Item Delegate
extension EditGroupSceneVC: UpdateItem{
    func deleteTapped(name: String) {
        Alert.showConfirmDelete(title: "Delete Scene", message: "Are you sure you want to delete \(sceneName)?", vc: self) {

            print("delete the scene when delete is pressed")
            guard let url = URL(string: "http://\(self.bridgeIP)/api/\(self.bridgeUser)/scenes/\(self.sceneID)") else {return}
            DataManager.sendRequest(method: .delete, url: url, httpBody: [:]) { (results) in
                DispatchQueue.main.async {
                    switch results{
                    case .success(let response):
                        if response.contains("success"){
                            Alert.showBasic(title: "Deleted!", message: "Successfully deleted \(self.sceneName)", vc: self)
                        } else {
                            Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                        }
                    case .failure(let e): print("Error occured: \(e)")
                    }
                }
            }
        }
    }
    //MARK: - Save Tapped
    func saveTapped(name: String) {
        if sceneID == Constants.newScene.rawValue{
            addNewScene(name: name)
        } else {
            if name != sceneName{
                guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/scenes/\(sceneID)") else {return}
                print(url)
                let httpBody = ["name": name]
                
                DataManager.sendRequest(method: .put, url: url, httpBody: httpBody) { (result) in
                    DispatchQueue.main.async {
                        switch result{
                        case .success(let response):
                            if response.contains("success"){
                                Alert.showBasic(title: "Saved!", message: "Successfully updated \(self.sceneName)", vc: self)
                            } else {
                                Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                            }
                        case .failure(let e): print("Error occured: \(e)")
                        }
                    }
                }
            }
        }
        updateLightState(sceneID: sceneID)
    }
    //MARK: - Edit List
    func editList() {
        
    }
    //MARK: - Add New Scene
    func addNewScene(name: String){
        print("No key, adding scene to bridge")
        guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/scenes") else {return}
        print(url)
        var httpBody = [String: Any]()
        httpBody["name"] = name
        httpBody["recycle"] = false
        httpBody["group"] = group.id
        httpBody["type"] = "GroupScene"
        print(httpBody)
        
        DataManager.sendRequest(method: .post, url: url, httpBody: httpBody) { (results) in
            DispatchQueue.main.async {
                switch results{
                case .success(let response):
                    //once the above info has created a scene key, it will give that to us which we can then use to update the light state for that scene's ID
                    if response.contains("success"){
                        do {
                            if let jsondata = response.data(using: .utf8){
                                let successResults = try JSONDecoder().decode([SuccessFromBridge].self, from: jsondata)
                                for x in successResults{
                                    self.sceneID = x.success.id
                                }
                                
                                self.updateLightState(sceneID: self.sceneID)
                                
                            }
                        }catch let e{
                            print(e)
                        }
                    } else {
                        Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                    }
                case .failure(let e): print("Error occured: \(e)")
                }
            }
        }
    }
    //MARK: - Update Light State
    func updateLightState(sceneID: String){
        for light in sceneLights{
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/scenes/\(sceneID)/lightstates/\(light.key)") else {return}
            print(url)
            var httpBody = [String: Any]()
            httpBody["on"] = light.value.on
            httpBody["bri"] = light.value.bri
            httpBody["xy"] = light.value.xy
            
            DataManager.sendRequest(method: .put, url: url, httpBody: httpBody) { (result) in
                DispatchQueue.main.async {
                    switch result{
                    case .success(let response):
                        if response.contains("success"){
                            Alert.showBasic(title: "Saved!", message: "Successfully updated \(self.sceneName)", vc: self)
                        } else {
                            Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                        }
                    case .failure(let e): print("Error occured: \(e)")
                    }
                }
            }
        }
    }
}
