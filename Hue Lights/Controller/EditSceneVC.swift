//
//  EditSceneVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/6/20.
//

import UIKit

class EditSceneVC: UIViewController, ListSelectionControllerDelegate{
    var sourceItems: [String]
    var hueResults : [HueModel]
    var bridgeIP: String
    var bridgeUser: String
    

    
    fileprivate var rootView : EditSceneView!
    fileprivate var subView : LightsListVC!
    fileprivate var sceneName: String
    fileprivate var hueLights = [HueModel.Light]()
    fileprivate var sceneKey: String?
    fileprivate var sceneLights = [String : HueModel.Lightstates]()
    fileprivate var tempChangeColorButton : UIButton?
    init(sceneName: String, sourceItems: [String], hueResults: [HueModel], bridgeIP: String, bridgeUser: String) {
        self.sceneName = sceneName
        self.sourceItems = sourceItems
        self.hueResults = hueResults
        self.bridgeIP = bridgeIP
        self.bridgeUser = bridgeUser
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func loadView() {
        super.loadView()
        rootView = EditSceneView(sceneName: sceneName)
        rootView.updateSceneDelegate = self
        subView = LightsListVC(showingGroup: false)
        subView.delegate = self
        addChildVC()
        self.view = rootView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Edit Scene"
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
        let rowName = sourceItems[indexPath.row]
        for x in hueResults{
            hueLights.append(contentsOf: x.lights.values)
        }
        let filtered = hueLights.filter({$0.name == rowName})
        for light in filtered{
            var lightXY = [Double]()
            var lightBri = Int()
            var lightOn = Bool()
            for x in hueResults{
                for i in x.lights{
                    if i.value.name == light.name{
                        if let safeXY = sceneLights[i.key]?.xy{
                            lightXY = safeXY
                        }
                        if let safeBri = sceneLights[i.key]?.bri{
                            lightBri = safeBri
                        }
                        if let safeOn = sceneLights[i.key]?.on{
                            lightOn = safeOn
                        }
                       
                        if let tag = Int(i.key){
                            cell.onSwitch.tag = tag
                            cell.brightnessSlider.tag = tag
                            cell.btnChangeColor.tag = tag
                        }
                    }
                }
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
        return cell
    }
    //MARK: - Number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sourceItems.count
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
        for x in hueResults{
            for scene in x.scenes{
                if scene.value.name == sceneName{
                    sceneKey = scene.key
                }
            }
        }
        
        
        if let safeSceneKey = sceneKey{
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/scenes/\(safeSceneKey)") else {return}
            print(url)
            DataManager.get(url: url) { (results) in
                switch results{
                case.success(let data):
                    do {
                        if let JSONString = String(data: data, encoding: String.Encoding.utf8){
                            print(JSONString)
                        }
                        let resultsFromBridge = try JSONDecoder().decode(HueModel.Scenes.self, from: data)

                        if let safeLightStates = resultsFromBridge.lightstates{
                            self.sceneLights = safeLightStates
                        }
                        for light in self.sceneLights{
                            print("light key: \(light.key), light xy: \(light.value.xy)")
                        }
                    }
                case .failure(let e): print("error: \(e)")
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
    func saveTapped(name: String) {
        guard let sceneKey = sceneKey else {return}
        //update name
        if name != sceneName{
            
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/scenes/\(sceneKey)") else {return}
            print(url)
            let httpBody = ["name": name]
            
            DataManager.put(url: url, httpBody: httpBody) { (result) in
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

        //update color, on and bri
        for light in sceneLights{
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/scenes/\(sceneKey)/lightstates/\(light.key)") else {return}
            print(url)
            var httpBody = [String: Any]()
            httpBody["on"] = light.value.on
            httpBody["bri"] = light.value.bri
            httpBody["xy"] = light.value.xy
            
            DataManager.put(url: url, httpBody: httpBody) { (result) in
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
    
    func editList() {
        
    }
    
    
}
