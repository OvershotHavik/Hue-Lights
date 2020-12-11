//
//  EditSceneVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/6/20.
//

import UIKit

class EditSceneVC: UIViewController, ListSelectionControllerDelegate{
    var sourceItems = [String]()
    var hueResults : HueModel?
    var bridgeIP = String()
    var bridgeUser = String()
    

    weak var delegate: ListSelectionControllerDelegate?
    fileprivate var rootView : EditSceneView!
    fileprivate var subView : LightsListVC!
    fileprivate var sceneName: String
    fileprivate var groupLights = [HueModel.Light]()
    fileprivate var sceneKey : String?
    fileprivate var sceneLights = [String : HueModel.Lightstates]()
    fileprivate var tempChangeColorButton : UIButton?
    fileprivate var groupNumber : String
    fileprivate var lightsInGroup : [HueModel.Light]
    init(sceneName: String, groupNumber: String, lightsInGroup: [HueModel.Light]) {
        self.sceneName = sceneName
        self.groupNumber = groupNumber
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
        subView = LightsListVC(lightsArray: [], showingGroup: false)
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
        hueResults = delegate.hueResults
        lightsInGroup = lightsInGroup.sorted(by: {$0.name < $1.name})
        subView.tableView.reloadData()
//        sourceItems = delegate.sourceItems.sorted()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        getSceneLightStates()

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
extension EditSceneVC: HueCellDelegate, UITableViewDataSource{
    //change the light list VC's cell's to match what the scene shows, not what is currently on the light
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        
        
        /*
         // broken untill we get ht ekey inside the model

        
        let lightID = lightsInGroup[indexPath.row] // key for the light
        if let safeLights = hueResults?.lights.filter({$0.key == lightID}){
            if let light = safeLights.first?.value{
                var lightBri = 1
                var lightXY = [Double]()
                var lightOn = Bool()
                if let safeXY = sceneLights[lightID]?.xy{
                    lightXY = safeXY
                }
                if let safeBri = sceneLights[lightID]?.bri{
                    lightBri = safeBri
                }
                if let safeOn = sceneLights[lightID]?.on{
                    lightOn = safeOn
                }
                if let tag = Int(lightID){
                    cell.onSwitch.tag = tag
                    cell.brightnessSlider.tag = tag
                    cell.btnChangeColor.tag = tag
                }
                let reachable = light.state.reachable
                let cellData = LightData(lightName: light.name,
                                         isOn: lightOn,
                                         brightness: Float(lightBri),
                                         isReachable: reachable,
                                         lightColor: ConvertColor.getRGB(xy: lightXY, bri: lightBri))

                cell.configureCell(LightData: cellData)
                cell.backgroundColor = .clear
            }
        }
 */
        return cell
    }
    //MARK: - Number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lightsInGroup.count
    }
    
    //MARK: - On Switch Toggled
    func onSwitchToggled(sender: UISwitch) {
        print("sender tag: \(sender.tag)")
        for light in sceneLights{
            if sender.tag == Int(light.key){
                let isOn = sender.isOn
                if let currentBri = sceneLights[light.key]?.bri,
                   let currentXY = sceneLights[light.key]?.xy{
                    let lightStateData = HueModel.Lightstates(on: isOn, bri: currentBri, xy: currentXY)
                    sceneLights[light.key] = lightStateData
                    print("New isOn for \(sender.tag): \(isOn)")
                }
            }
        }
    }
    //MARK: - Brightness Slider Changed
    func brightnessSliderChanged(sender: UISlider) {
        for light in sceneLights{
            if sender.tag == Int(light.key){
                let newBri = sender.value
                if let currentIsOn = sceneLights[light.key]?.on,
                   let currentXY = sceneLights[light.key]?.xy{
                    let lightStateData = HueModel.Lightstates(on: currentIsOn, bri: Int(newBri), xy: currentXY)
                    sceneLights[light.key] = lightStateData
//                    print("New bri for \(sender.tag): \(newBri)")
                }
            }
        }
    }
    //MARK: - Change Light Color tapped
    func changeLightColor(sender: UIButton) {
        print("sender tag: \(sender.tag)")
        print("change light color tapped")
        subView.selectColor()
        tempChangeColorButton = sender
    }
    //MARK: - Update Light Color once picked from color picker
    func updatLightColor(){
        guard let tempChangeColorButton = tempChangeColorButton else {return}
//        guard let delegate = delegate else { return}
        tempChangeColorButton.backgroundColor = subView.pickedColor
        
        let red = subView.pickedColor.components.red
        let green = subView.pickedColor.components.green
        let blue = subView.pickedColor.components.blue
        let colorXY = ConvertColor.getXY(red: red, green: green, blue: blue)
        for light in sceneLights{
            if tempChangeColorButton.tag == Int(light.key){
                if let currentBri = sceneLights[light.key]?.bri,
                   let currentOn = sceneLights[light.key]?.on{
                    let lightStateData = HueModel.Lightstates(on: currentOn, bri: currentBri, xy: colorXY)
                    sceneLights[light.key] = lightStateData
                    print("New color for \(tempChangeColorButton.tag): \(colorXY)")
                }
            }
        }
    }
    //MARK: - Get Scene Light State From Bridge
    func getSceneLightStates(){
        if let hueResults = hueResults{
            for scene in hueResults.scenes{
                if scene.value.name == sceneName{
                    sceneKey = scene.key
                }
            }
        }
        
        
        if let safeSceneKey = sceneKey{ // existing scene
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/scenes/\(safeSceneKey)") else {return}
            print(url)
            DataManager.get(url: url) { (results) in
                switch results{
                case.success(let data):
                    do {
                        print("before json string")
                        if let JSONString = String(data: data, encoding: String.Encoding.utf8){
                            print(JSONString)
                        }
                        
                        let resultsFromBridge = try JSONDecoder().decode(HueModel.Scenes.self, from: data)
                        

                        if let safeLightStates = resultsFromBridge.lightstates{
                            self.sceneLights = safeLightStates
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
        } else { // new scene
           print("No scene key, adding lights listed into scenelights")
            if let hueResults = hueResults{
                for light in hueResults.lights{
                    
                    
                    //broken untill we get the key inside the model
                    
                    
                    
//                    if let filtered = lightsInGroup.filter({$0 == light}){
//                    if lightsInGroup.contains(light.value.name){
//                    if lightsInGroup.contains(light.value.name){
//                    if sourceItems.contains(light.value.name){
//                        let lightStateData = HueModel.Lightstates(on: true, bri: 100, xy:[])
//                        sceneLights[light.key] = lightStateData
//                    }
                }
            }
        }
    }
    
}
//MARK: - Color Picker Delegate
extension EditSceneVC: UIColorPickerViewControllerDelegate{
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        subView.pickedColor = viewController.selectedColor
        updatLightColor()
    }
}

//MARK: - Update Item Delegate
extension EditSceneVC: UpdateItem{
    func deleteTapped(name: String) {
        Alert.showConfirmDelete(title: "Delete Scene", message: "Are you sure you want to delete \(sceneName)?", vc: self) {
            guard let sceneKey = self.sceneKey else {return}

            print("delete the scene when delete is pressed")
            guard let url = URL(string: "http://\(self.bridgeIP)/api/\(self.bridgeUser)/scenes/\(sceneKey)") else {return}
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
        guard let sceneKey = sceneKey else {
            addNewScene(name: name)
            return
        }
        //update name
        if name != sceneName{
            
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/scenes/\(sceneKey)") else {return}
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
        updateLightState(sceneKey: sceneKey)
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
        httpBody["group"] = groupNumber
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
                                    self.sceneKey = x.success.id
                                }
                                
                                if let safeSceneKey = self.sceneKey{
                                    self.updateLightState(sceneKey: safeSceneKey)
                                }
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
    func updateLightState(sceneKey: String){
        for light in sceneLights{
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/scenes/\(sceneKey)/lightstates/\(light.key)") else {return}
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
