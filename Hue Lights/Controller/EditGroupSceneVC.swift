//
//  EditSceneVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/6/20.
//

import UIKit

class EditGroupSceneVC: UIViewController{
    weak var updateDelegate : UpdateScenes?
    lazy var noAlertOnSuccessClosure : (Result<String, NetworkError>) -> Void = {Result in
        DispatchQueue.main.async {
            switch Result{
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
    lazy var alertClosure : (Result<String, NetworkError>, _ message: String) -> Void = {Result, message  in
        DispatchQueue.main.async {
            switch Result{
            case .success(let response):
                if response.contains("success"){
                    Alert.showBasic(title: "Success", message: message, vc: self)
                } else {
                    Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                }
            case .failure(let e): print("Error occured: \(e)")
            }
        }
    }
    
    fileprivate var rootView : EditSceneView!
    fileprivate var subView : LightsListVC!
    fileprivate var sceneName: String
    fileprivate var groupLights = [HueModel.Light]()
    fileprivate var sceneID : String
    fileprivate var sceneLights = [String : HueModel.Lightstates]()
    fileprivate var tempChangeColorButton : UIButton?
    fileprivate var group : HueModel.Groups
    fileprivate var lightsInGroup : [HueModel.Light]
    fileprivate var baseURL: String
    init(baseURL: String, sceneName: String, sceneID: String, group: HueModel.Groups, lightsInGroup: [HueModel.Light]) {
        self.baseURL = baseURL
        self.sceneName = sceneName
        self.sceneID = sceneID
        self.group = group
        self.lightsInGroup = lightsInGroup
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - Load View
    override func loadView() {
        super.loadView()
        rootView = EditSceneView(sceneName: sceneName)
        rootView.updateSceneDelegate = self
        subView = LightsListVC(baseURL: "put base url here", lightsArray: lightsInGroup, showingGroup: nil)
        addChildVC()
        self.view = rootView
    }
    //MARK: - View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Edit Scene"
        lightsInGroup = lightsInGroup.sorted(by: {$0.name < $1.name})
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
        DataManager.get(baseURL: baseURL,
                        HueSender: .scenes) { results in
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
        var light = lightsInGroup[indexPath.row]
        let config = sceneLights[light.id]
        light.state.bri = 1
        if let safeBRI = config?.bri{
            light.state.bri = safeBRI
        }
        if let safeXY = config?.xy{
            light.state.xy = safeXY
        }
        if let safeLightOn = config?.on{
            light.state.on = safeLightOn
        }
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
        return lightsInGroup.count
    }
    
    //MARK: - On Switch Toggled
    func onSwitchToggled(sender: UISwitch) {
        print("sender tag: \(sender.tag)")
        let lightIDKey = String(sender.tag)
        let light = sceneLights[lightIDKey]
        if let currentBRI = light?.bri,
           let currentXY = light?.xy{
            let lightStateData = HueModel.Lightstates(on: sender.isOn,
                                                      bri: currentBRI,
                                                      xy: currentXY)
            sceneLights[lightIDKey] = lightStateData
            //Apply to light
            let lightID = String(lightIDKey)
            let httpBody = ["on": sender.isOn]
            DataManager.updateLight(baseURL: baseURL,
                                    lightID: lightID,
                                    method: .put,
                                    httpBody: httpBody,
                                    completionHandler: noAlertOnSuccessClosure)
        }
    }
    //MARK: - Brightness Slider Changed
    func brightnessSliderChanged(sender: UISlider) {
        let lightIDKey = String(sender.tag)
        let light = sceneLights[lightIDKey] // used to verify values below
        if let currentIsOn = light?.on,
           let currentXY = light?.xy{
            let lightStateData = HueModel.Lightstates(on: currentIsOn,
                                                      bri: Int(sender.value),
                                                      xy: currentXY)
            sceneLights[lightIDKey] = lightStateData
            //Apply to light
            let lightID = String(lightIDKey)
            let httpBody = ["bri": Int(sender.value)]
            DataManager.updateLight(baseURL: baseURL,
                                    lightID: lightID,
                                    method: .put,
                                    httpBody: httpBody,
                                    completionHandler: noAlertOnSuccessClosure)
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
        let lightIDKey = String(tempChangeColorButton.tag)
        let red = subView.pickedColor.components.red
        let green = subView.pickedColor.components.green
        let blue = subView.pickedColor.components.blue
        let colorXY = ConvertColor.getXY(red: red, green: green, blue: blue)
        let light = sceneLights[lightIDKey] // used to verify values exist below
        if let currentBri = light?.bri,
           let currentOn = light?.on{
            let lightStateData = HueModel.Lightstates(on: currentOn,
                                                      bri: currentBri,
                                                      xy: colorXY)
            sceneLights[lightIDKey] = lightStateData
    
            //Apply to light
            let lightID = String(lightIDKey)
            let httpBody = ["xy": colorXY]
            DataManager.updateLight(baseURL: baseURL,
                                    lightID: lightID,
                                    method: .put,
                                    httpBody: httpBody,
                                    completionHandler: noAlertOnSuccessClosure)
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
            DataManager.getSceneLightStates(baseURL: baseURL,
                                            sceneID: sceneID,
                                            HueSender: .scenes) { results in
                switch results{
                case.success(let data):
                    do {
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
        for light in sceneLights{
            let lightID = String(light.key)
            var httpBody = [String: Any]()
            httpBody["on"] = light.value.on
            httpBody["bri"] = Int(light.value.bri)
            if let safeXY = light.value.xy{
                httpBody["xy"] = safeXY
            }
            DataManager.updateLight(baseURL: baseURL,
                                    lightID: lightID,
                                    method: .put,
                                    httpBody: httpBody,
                                    completionHandler: noAlertOnSuccessClosure)
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
        }
        updateLightState(sceneID: sceneID)
    }
    //MARK: - Edit List
    func editList() {
        
    }
    //MARK: - Add New Scene
    func addNewScene(name: String){
        print("No key, adding scene to bridge")

        var httpBody = [String: Any]()
        httpBody["name"] = name
        httpBody["recycle"] = false
        httpBody["group"] = group.id
        httpBody["type"] = "GroupScene"
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
        for light in sceneLights{
            var httpBody = [String: Any]()
            httpBody["on"] = light.value.on
            httpBody["bri"] = light.value.bri
            httpBody["xy"] = light.value.xy
            DataManager.updateLightStateInScene(baseURL: baseURL,
                                                sceneID: sceneID,
                                                lightID: light.key,
                                                method: .put,
                                                httpBody: httpBody) { results in
                self.alertClosure(results, "Successfully updated \(self.sceneName)")
            }
        }
    }
}
