//
//  EditSceneVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/6/20.
//

import UIKit

class EditSceneVC: UIViewController, UpdateItem{

    
    weak var updateDelegate : UpdateScenes?
    lazy var noAlertOnSuccessClosure : (Result<String, NetworkError>) -> Void = {Result in
        DispatchQueue.main.async {
            switch Result{
            case .success(let response):
                if response.contains("success"){
                    //don't display an alert if successful
                } else {
                    Alert.showBasic(title: "Error occurred", message: response, vc: self) // will need changed later
                }
            case .failure(let e): print("Error occurred: \(e)")
            }
        }
    }
    lazy var alertClosure : (Result<String, NetworkError>, _ message: String) -> Void = {Result, message  in
        DispatchQueue.main.async {
            switch Result{
            case .success(let response):
                if response.contains("success"){
                    Alert.showBasic(title: "Success", message: message, vc: self)
                } else {
                    Alert.showBasic(title: "Error occurred", message: response, vc: self) // will need changed later
                }
            case .failure(let e): print("@objc Error occurred: \(e)")
            }
        }
    }
    
    fileprivate var rootView : EditSceneView!
    fileprivate var subView : LightsListVC!
    fileprivate var sceneName: String
    fileprivate var sceneID : String
    fileprivate var tempChangeColorButton : UIButton?
    fileprivate var group : HueModel.Groups?
    fileprivate var lightsInScene : [HueModel.Light]
    fileprivate var baseURL: String
    init(baseURL: String, sceneName: String, sceneID: String, group: HueModel.Groups?, lightsInScene: [HueModel.Light]) {
        self.baseURL = baseURL
        self.sceneName = sceneName
        self.sceneID = sceneID
        self.group = group
        self.lightsInScene = lightsInScene
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - Load View
    override func loadView() {
        super.loadView()
        if group != nil{
            rootView = EditSceneView(sceneName: sceneName, showingGroupScene: true)
        } else {
            rootView = EditSceneView(sceneName: sceneName, showingGroupScene: false)
        }
        rootView.updateSceneDelegate = self
        subView = LightsListVC(baseURL: baseURL, lightsArray: lightsInScene, showingGroup: nil)
        addChildVC()
        self.view = rootView
    }
    //MARK: - View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Edit Scene"
//        getSceneLightStates()
        lightsInScene = lightsInScene.sorted(by: {$0.name < $1.name})
        subView.tableView.reloadData()
        
    }
    //MARK: - View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        getSceneLightStates()
        
    }
    //MARK: - View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        updateSceneListVC()
    }
    //MARK: - Update Scene List VC
    func updateSceneListVC(){
        let appOwner = "0ZaZRrSyiEoQYiw05AKrHmKsOuIcpcu1W8mb0Qox"
        if let safeGroup = group{
            DataManager.get(baseURL: baseURL,
                            HueSender: .scenes) { results in
                switch results{
                case .success(let data):
                    do {
                        let scenesFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Scenes>.self, from: data)
                        let scenes = scenesFromBridge.compactMap {$0}
                        let sceneArray = scenes.filter{$0.group == safeGroup.id}
                        self.updateDelegate?.updateScenesDS(items: sceneArray)
                    } catch let e {
                        print("Error getting scenes: \(e)")
                    }
                case .failure(let e): print(e)
                }
            }
        } else {
            print("Update light group list")
            DataManager.get(baseURL: baseURL,
                            HueSender: .scenes) { results in
                switch results{
                case .success(let data):
                    do {
                        let scenesFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Scenes>.self, from: data)
                        let scenes = scenesFromBridge.compactMap {$0}
                        let lightScenes = scenes.filter({$0.type == "LightScene"})
                        let ownedScenes = lightScenes.filter({$0.owner == appOwner}) // to display only scenes created by this app
                        for scene in ownedScenes{
                            print("Light Scene Name: \(scene.name)")
                        }
                        self.updateDelegate?.updateScenesDS(items: ownedScenes)
                    } catch let e {
                        print("Error getting scenes: \(e)")
                    }

                case .failure(let e): print(e)
                }
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
    //MARK: - Identify Tapped
    func identifyTapped() {
        print("identify tapped in edit scene vc")
        let httpBody = ["alert": "select"]
        for light in lightsInScene{
            DataManager.updateLight(baseURL: baseURL,
                                    lightID: light.id,
                                    method: .put,
                                    httpBody: httpBody,
                                    completionHandler: noAlertOnSuccessClosure)
        }
    }
    //MARK: - Update Delegate functions
    //MARK: - Delete Tapped
    func deleteTapped(name: String) {
        Alert.showConfirmDelete(title: "Delete Scene", message: "Are you sure you want to delete \(sceneName)?", vc: self) {

            print("delete the scene when delete is pressed")
            DataManager.updateScene(baseURL: self.baseURL,
                                    sceneID: self.sceneID,
                                    method: .delete,
                                    httpBody: [:]) { results in
                self.alertClosure(results, "Successfully deleted \(self.sceneName)")
            }
        }
    }
    //MARK: - Save Tapped
    func saveTapped(name: String) {
        if sceneID == Constants.newScene.rawValue{
            addNewScene(name: name)
        } else {
            if name != sceneName{
                let httpBody = ["name": name]
                DataManager.updateScene(baseURL: baseURL,
                                        sceneID: sceneID,
                                        method: .put,
                                        httpBody: httpBody) { results in
                    self.alertClosure(results, "Successfully updated \(self.sceneName)")
                }
            }
            if group == nil{ // Update the list of lights if no gorup
                let lightIDs = lightsInScene.map({$0.id})
                let httpBody = ["lights": lightIDs]
                DataManager.updateScene(baseURL: baseURL,
                                        sceneID: sceneID,
                                        method: .put,
                                        httpBody: httpBody,
                                        completionHandler: self.noAlertOnSuccessClosure)
            }
            updateLightState(sceneID: sceneID)
        }
    }
    //MARK: - Edit List
    func editList() {
        DataManager.get(baseURL: baseURL,
                        HueSender: .lights) { results in
            switch results{
            case .success(let data):
                do {
                    let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                    let lights = lightsFromBridge.compactMap{ $0}
                    DispatchQueue.main.async {
                        let modifySelectedLightsVC = ModifyLightsInGroupVC(limit: 20,
                                                                selectedItems: self.lightsInScene,
                                                                lightsArray: lights)
                        modifySelectedLightsVC.selectedItemsDelegate = self
                        modifySelectedLightsVC.title = HueSender.lights.rawValue
                        self.navigationController?.pushViewController(modifySelectedLightsVC, animated: true)
                    }
                } catch let e {
                    print("Error getting lights: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
    }
    //MARK: - Add New Scene
    func addNewScene(name: String){
        let lightIDs = lightsInScene.map({$0.id})
        print("lightIDs: \(lightIDs)")
        print("No key, adding scene to bridge")
        
        var httpBody = [String: Any]()
        httpBody["name"] = name
        httpBody["recycle"] = false
        if let safeGroup = group{
            httpBody["group"] = safeGroup.id
            httpBody["type"] = "GroupScene"
        } else {
            httpBody["lights"] = lightIDs
            httpBody["type"] = "LightScene"
        }
        
        print(httpBody)
        DataManager.createNewScene(baseURL: baseURL,
                                   httpBody: httpBody) { results in
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
        for light in lightsInScene{
            var httpBody = [String: Any]()
            httpBody["on"] = light.state.on
            httpBody["bri"] = light.state.bri
            httpBody["xy"] = light.state.xy
            DataManager.updateLightStateInScene(baseURL: baseURL,
                                                sceneID: sceneID,
                                                lightID: light.id,
                                                method: .put,
                                                httpBody: httpBody) { results in
                self.alertClosure(results, "Successfully updated \(self.sceneName)")
            }
        }
    }
}


//MARK: - SubVIew Tableview dataSource
extension EditSceneVC: HueCellDelegate, UITableViewDataSource{
    //change the light list VC's cell's to match what the scene shows, not what is currently on the light
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        let light = lightsInScene[indexPath.row]
        cell.configureLightCell(light: light)
        if let tag = Int(light.id){
            cell.onSwitch.tag = tag
            cell.brightnessSlider.tag = tag
            cell.btnChangeColor.tag = tag
        }
        cell.backgroundColor = .clear
        return cell
    }
    //MARK: - Number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lightsInScene.count
    }
    
    //MARK: - On Switch Toggled
    func onSwitchToggled(sender: UISwitch) {
        print("sender tag: \(sender.tag)")
        let lightID = String(sender.tag)
        let filtered = lightsInScene.filter({$0.id == lightID})
        if let light = filtered.first{
            if let index = lightsInScene.firstIndex(of: light){
                lightsInScene[index].state.on = sender.isOn
                let httpBody = ["on": sender.isOn]
                DataManager.updateLight(baseURL: baseURL,
                                        lightID: lightID,
                                        method: .put,
                                        httpBody: httpBody,
                                        completionHandler: noAlertOnSuccessClosure)
            }
        }
    }
    //MARK: - Brightness Slider Changed
    func brightnessSliderChanged(sender: UISlider) {
        let lightID = String(sender.tag)
        let filtered = lightsInScene.filter({$0.id == lightID})
        if let light = filtered.first{
            if let index = lightsInScene.firstIndex(of: light){
                lightsInScene[index].state.bri = Int(sender.value)
                let httpBody = ["bri": Int(sender.value)]
                DataManager.updateLight(baseURL: baseURL,
                                        lightID: lightID,
                                        method: .put,
                                        httpBody: httpBody,
                                        completionHandler: noAlertOnSuccessClosure)
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
    func updateLightColor(){
        guard let tempChangeColorButton = tempChangeColorButton else {return}
        tempChangeColorButton.backgroundColor = subView.pickedColor
//        let tag = tempChangeColorButton.tag
        let lightID = String(tempChangeColorButton.tag)
        let red = subView.pickedColor.components.red
        let green = subView.pickedColor.components.green
        let blue = subView.pickedColor.components.blue
        let colorXY = ConvertColor.getXY(red: red, green: green, blue: blue)
        let filtered = lightsInScene.filter({$0.id == lightID})
        if let light = filtered.first{
            if let index = lightsInScene.firstIndex(of: light){
                lightsInScene[index].state.xy = colorXY
                let httpBody = ["xy": colorXY]
                DataManager.updateLight(baseURL: baseURL,
                                        lightID: lightID,
                                        method: .put,
                                        httpBody: httpBody,
                                        completionHandler: noAlertOnSuccessClosure)
            }
        }
    }
    //MARK: - Get Scene Light State From Bridge
    func getSceneLightStates(){
            DataManager.getSceneLightStates(baseURL: baseURL,
                                            sceneID: sceneID,
                                            HueSender: .scenes) { results in
                switch results{
                case.success(let data):
                    do {
                        let resultsFromBridge = try JSONDecoder().decode(HueModel.IndividualScene.self, from: data)
                        if let safeLightStates = resultsFromBridge.lightstates{
                            for lightState in safeLightStates{
                                let filtered = self.lightsInScene.filter({$0.id == lightState.key})
                                if let light = filtered.first{
                                    if let index = self.lightsInScene.firstIndex(of: light){
                                        self.lightsInScene[index].state.on = lightState.value.on
                                        self.lightsInScene[index].state.bri = lightState.value.bri
                                        self.lightsInScene[index].state.xy = lightState.value.xy
                                    }
                                }
                            }
                            self.applyLightStatesToLights()
                        }
                        for light in self.lightsInScene{
                            print("light id: \(light.id), xy: \(light.state.xy ?? [0,0]),  bri: \(light.state.bri)")
                        }
                    } catch let e{
                        print(e)
                    }
                case .failure(let e): print("error: \(e)")
                }
            }
        
    }
    //MARK: - Apply Light States To Lights
    func applyLightStatesToLights(){
        for light in lightsInScene{
//            let lightID = String(light.key)
            var httpBody = [String: Any]()
            httpBody["on"] = light.state.on
            httpBody["bri"] = Int(light.state.bri)
            if let safeXY = light.state.xy{
                httpBody["xy"] = safeXY
            }
            DataManager.updateLight(baseURL: baseURL,
                                    lightID: light.id,
                                    method: .put,
                                    httpBody: httpBody,
                                    completionHandler: noAlertOnSuccessClosure)
        }
    }
}
//MARK: - Color Picker Delegate
extension EditSceneVC: UIColorPickerViewControllerDelegate{
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        subView.pickedColor = viewController.selectedColor
        updateLightColor()
    }
}

//MARK: - SelectedLightsDelegate
extension EditSceneVC: SelectedLightsDelegate{
    func selectedLights(lights: [HueModel.Light]) {
        self.lightsInScene = lights.sorted(by: {$0.name < $1.name})
        DispatchQueue.main.async {
            self.subView.lightsArray = self.lightsInScene
            self.subView.tableView.reloadData()
        }
    }
    
    
}
