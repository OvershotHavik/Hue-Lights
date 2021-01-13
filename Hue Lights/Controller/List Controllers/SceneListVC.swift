//
//  SceneListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/2/20.
//

import UIKit

class SceneListVC: ListController{
    fileprivate var sceneArray : [HueModel.Scenes]
    fileprivate var sceneLights = [String : HueModel.Lightstates]()
    fileprivate var originalSceneArray : [HueModel.Scenes] // used for search
    fileprivate var group: HueModel.Groups?
    fileprivate var lightsInScene: [HueModel.Light]
    fileprivate var baseURL: String
    fileprivate var appOwner: String?
    init(baseURL : String, group: HueModel.Groups?, lightsInScene: [HueModel.Light], sceneArray: [HueModel.Scenes], appOwner: String?) {
        self.baseURL = baseURL
        self.group = group
        self.lightsInScene = lightsInScene
        self.sceneArray = sceneArray
        self.originalSceneArray = sceneArray
        self.appOwner = appOwner
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        sceneArray = sceneArray.sorted(by: { $0.name < $1.name})
        self.tableView.reloadData()
    }
    //MARK: - View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        colorPicker.delegate = self
        tableView.register(ListCell.self, forCellReuseIdentifier: Cells.cell)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 50
        searchController.searchBar.isTranslucent = false
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addScene))
        setup()
    }
    //MARK: - Objc - Add Scene
    @objc func addScene(){
        print("Bring up Add scene")
        if let safeGroup = group{
            let addScene = EditSceneVC(baseURL: baseURL,
                                       sceneName: "",
                                       sceneID: Constants.newScene.rawValue,
                                       group: safeGroup,
                                       lightsInScene: lightsInScene,
                                       appOwner: appOwner)
            addScene.updateDelegate = self
            self.navigationController?.pushViewController(addScene, animated: true)
        } else { // light scenes
            let addScene = EditSceneVC(baseURL: baseURL,
                                       sceneName: "",
                                       sceneID: Constants.newScene.rawValue,
                                       group: nil,
                                       lightsInScene: [],
                                       appOwner: appOwner)
            addScene.updateDelegate = self
            self.navigationController?.pushViewController(addScene, animated: true)
        }
    }
//MARK: - Cell For Row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! ListCell
        cell.accessoryType = .none
        cell.backgroundColor = .systemBackground
        let itemRow = sceneArray[indexPath.row]
        cell.lblListItem.text = itemRow.name
        return cell
    }
    //MARK: - Number Of Rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sceneArray.count
    }
    //MARK: - Did Select Row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let scene = sceneArray[indexPath.row]
        if let safeGroup = group{
            print("Selected Scene: \(scene.name)")
            let httpBody = [Keys.scene.rawValue : scene.id]
            DataManager.updateGroup(baseURL: baseURL,
                                    groupID: safeGroup.id,
                                    method: .put,
                                    httpBody: httpBody,
                                    completionHandler: self.noAlertOnSuccessClosure)
        } else {
            getSceneLightStates(scene: scene, editing: false)
        }
    }
    //MARK: - Get Scene Light State From Bridge
    func getSceneLightStates(scene: HueModel.Scenes, editing: Bool){
        DataManager.getSceneLightStates(baseURL: baseURL,
                                        sceneID: scene.id,
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
    
    //MARK: - Apply Light States To Lights
    func applyLightStatesToLights(){
        for light in sceneLights{
            let lightID = String(light.key)
            var httpBody = [String: Any]()
            httpBody[Keys.on.rawValue] = light.value.on
            httpBody[Keys.bri.rawValue] = Int(light.value.bri)
            if let safeXY = light.value.xy{
                httpBody[Keys.xy.rawValue] = safeXY
            }
            DataManager.updateLight(baseURL: baseURL,
                                    lightID: lightID,
                                    method: .put,
                                    httpBody: httpBody,
                                    completionHandler: noAlertOnSuccessClosure)
        }
    }
//MARK: - Leading Swipe Action
     func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
         let edit = self.edit(indexPath: indexPath)
         let swipe = UISwipeActionsConfiguration(actions: [edit])
         return swipe
     }
//MARK: - Leading Swipe Action - Edit
    func edit(indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Edit") { (_, _, _) in
            print("Take user to edit scene")
            
            if self.group == nil{
                DataManager.get(baseURL: self.baseURL,
                                HueSender: .scenes) { results in
                    switch results{
                    case .success(let data):
                        do {
                            let scenesFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Scenes>.self, from: data)
                            let scenes = scenesFromBridge.compactMap {$0}
                            let filteredScene = scenes.filter({$0.id == self.sceneArray[indexPath.row].id})
                            if let updatedScene = filteredScene.first{
                                self.getLightModelForLightsInScene(scene: updatedScene)
                            }
                        } catch let e {
                            print("Error getting scenes: \(e)")
                        }

                    case .failure(let e): print(e)
                    }
                }
//                self.getLightModelForLightsInScene(scene: self.sceneArray[indexPath.row])
            } else {
                DispatchQueue.main.async {
                    let selected = self.sceneArray[indexPath.row]
                    let editScene = EditSceneVC(baseURL: self.baseURL,
                                                sceneName: selected.name,
                                                sceneID: selected.id,
                                                group: self.group,
                                                lightsInScene: self.lightsInScene,
                                                appOwner: self.appOwner)
                    editScene.updateDelegate = self
                    self.navigationController?.pushViewController(editScene, animated: true)
                }
            }
        }
        return action
     }
    //MARK: - Get Light Model For Lights In Scene
    func getLightModelForLightsInScene(scene: HueModel.Scenes){
        DataManager.get(baseURL: baseURL, HueSender: .lights) { results in
            switch results{
            case .success(let data):
                do {
                    let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                    let lights = lightsFromBridge.compactMap{ $0}
                    self.lightsInScene = lights.filter {return scene.lights.contains($0.id)}
                    print("lights in scene: \(self.lightsInScene.count)")
                    DispatchQueue.main.async {
                        let editScene = EditSceneVC(baseURL: self.baseURL,
                                                    sceneName: scene.name,
                                                    sceneID: scene.id,
                                                    group: self.group,
                                                    lightsInScene: self.lightsInScene,
                                                    appOwner: self.appOwner)
                        editScene.updateDelegate = self
                        self.navigationController?.pushViewController(editScene, animated: true)
                    }
                } catch let e {
                    print("Error getting lights: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
    }
//MARK: - Trailing Swipe Action - Delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let scene = sceneArray[indexPath.row]
        if editingStyle == .delete{
            Alert.showConfirmDelete(title: "Delete Scene?", message: "Are you sure you want to delete \(scene.name)?", vc: self) {
                print("Delete pressed")
                DataManager.updateScene(baseURL: self.baseURL,
                                        sceneID: scene.id,
                                        method: .delete,
                                        httpBody: [:]) { results in
                    self.alertClosure(results, "Successfully deleted \(scene.name).")
                }
                self.sceneArray.remove(at: indexPath.row)
                self.tableView.reloadData()
            }
        }
    }
}


//MARK: - Update Scenes
extension SceneListVC: UpdateScenes{
    func updateScenesDS(items: [HueModel.Scenes]) {
        DispatchQueue.main.async {
            self.sceneArray = items.sorted(by: {$0.name < $1.name})
            self.tableView.reloadData()
        }
    }
}

//MARK: - UI Search Bar Delegate
extension SceneListVC: UISearchBarDelegate{
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        sceneArray = originalSceneArray.sorted(by: {$0.name < $1.name})
        tableView.reloadData()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchText = searchText
        searchBar.text = searchText
        print("SearchText: \(searchText)")
        let filtered = sceneArray.filter {$0.name.contains(searchText)}
        self.sceneArray = filtered.isEmpty ? [] : filtered
        if searchText == ""{
            self.sceneArray = originalSceneArray.sorted(by: {$0.name < $1.name})
        }
        tableView.reloadData()
    }
}
