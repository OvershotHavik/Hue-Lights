//
//  EditLightSceneVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/14/20.
//

import UIKit
/*
class EditLightSceneVC: EditSceneVC{
    fileprivate var rootView : EditSceneView!
    fileprivate var subView : LightsListVC!
    fileprivate var sceneLights = [String : HueModel.Lightstates]()
    fileprivate var selectedLightsArray : [HueModel.Light]?
    fileprivate var sceneName: String
    fileprivate var sceneID : String
    fileprivate var baseURL: String
    init(baseURL: String, sceneName: String, sceneID: String) {
        self.sceneName = sceneName
        self.sceneID = sceneID
        self.baseURL = baseURL
        super.init(baseURL: baseURL, sceneName: sceneName, sceneID: sceneID, group: nil, lightsInGroup: [])
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - Load View
    override func loadView() {
//        super.loadView()
        rootView = EditSceneView(sceneName: sceneName, showingGroupScene: false)
        rootView.updateSceneDelegate = self
        self.view = rootView
        subView = LightsListVC(baseURL: baseURL,
                               lightsArray: selectedLightsArray ?? [],
                               showingGroup: nil)
        addChildVC()
        subView.view.backgroundColor = .blue
    }
    override func viewDidLoad() {
        
    }
    override func addChildVC(){
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
    
    override func editList() {
        DataManager.get(baseURL: baseURL,
                        HueSender: .lights) { results in
            switch results{
            case .success(let data):
                do {
                    let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                    let lights = lightsFromBridge.compactMap{ $0}
                    DispatchQueue.main.async {
                        let modifySelectedLightsVC = ModifyLightsInGroupVC(limit: 20,
                                                                selectedItems: self.selectedLightsArray ?? [],
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
    //MARK: - Delete Tapped
    override func deleteTapped(name: String) {
        
    }
    //MARK: - Save Tapped
    override func saveTapped(name: String) {
        
    }

    /*
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
    //MARK: - Get Scene Light State From Bridge
    func getSceneLightStates(){
        if sceneID == Constants.newScene.rawValue{
            print("New scene, adding lights listed into scenelights")
             for light in selectedLightsArray ?? []{
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
 */
}
/*
//MARK: - SubView - UITableViewDataSource, UIColorPickerViewControllerDelegate
extension EditLightSceneVC: UITableViewDataSource, UIColorPickerViewControllerDelegate{
    //MARK: - Number Of Rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedLightsArray?.count ?? 0
    }
    //MARK: - Cell for row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        guard let selectedLightsArray = selectedLightsArray else {return UITableViewCell()}
        var light = selectedLightsArray[indexPath.row]
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
    
    
}
//MARK: - HueCellDelegate
extension EditLightSceneVC: HueCellDelegate{
    func onSwitchToggled(sender: UISwitch) {
        <#code#>
    }
    
    func brightnessSliderChanged(sender: UISlider) {
        <#code#>
    }
    
    func changeLightColor(sender: UIButton) {
        <#code#>
    }
    
    
}
 
//MARK: - Update Item
extension EditLightSceneVC: UpdateItem{
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
                                                                selectedItems: self.selectedLightsArray ?? [],
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
    //MARK: - Delete Tapped
    func deleteTapped(name: String) {
        
    }
    //MARK: - Save Tapped
    func saveTapped(name: String) {
        
    }
}

 */
//MARK: - SelectedLightsDelegate
extension EditLightSceneVC: SelectedLightsDelegate{
    func selectedLights(lights: [HueModel.Light]) {
        self.selectedLightsArray = lights
        DispatchQueue.main.async {
            self.subView.tableView.reloadData()
        }
    }
}

*/
