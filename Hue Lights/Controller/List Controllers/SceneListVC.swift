//
//  SceneListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/2/20.
//

import UIKit

class SceneListVC: ListController, UISearchBarDelegate, ListSelectionControllerDelegate{
    var sourceItems = [String]()
    var bridgeIP = String()
    var bridgeUser = String()
    
//    fileprivate var filtered = [String]()
    fileprivate var sceneArray : [HueModel.Scenes]
    internal var hueResults : HueModel?
    fileprivate var groupNumber: String
    fileprivate var lightsInGroup: [HueModel.Light]
    
    init(groupNumber: String, lightsInGroup: [HueModel.Light], sceneArray: [HueModel.Scenes]) {
        self.groupNumber = groupNumber
        self.lightsInGroup = lightsInGroup
        self.sceneArray = sceneArray
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        guard let delegate = delegate else {
            assertionFailure("Set the delegate")
            return
        }
        bridgeIP = delegate.bridgeIP
        bridgeUser = delegate.bridgeUser
        hueResults = delegate.hueResults
        sceneArray = sceneArray.sorted(by: { $0.name < $1.name})
//        if let hueResults = hueResults{
//            sceneArray.append(contentsOf: hueResults.scenes.values)
//
//        }
        
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        colorPicker.delegate = self
        tableView.register(ListCell.self, forCellReuseIdentifier: Cells.cell) // change the cell depending on which VC is using this
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 50
        searchController.searchBar.isTranslucent = false
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addScene))
        setup()
    }
    
    @objc func addScene(){
        print("Bring up edit scene")
        let addScene = EditSceneVC(sceneName: "", groupNumber: groupNumber, lightsInGroup: lightsInGroup)
        addScene.delegate = self
//        self.sourceItems = self.lightsInGroup
        self.navigationController?.pushViewController(addScene, animated: true)
        
    }
    func getLightDataFromKey(){
        
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! ListCell
        cell.accessoryType = .none
        cell.backgroundColor = .systemBackground
        let itemRow = sceneArray[indexPath.row]
        cell.lblListItem.text = itemRow.name
        return cell
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sceneArray.count
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let delegate = delegate else {
            assertionFailure("Set the delegate")
            return
        }
        let selectedScene = sceneArray[indexPath.row].name
        print("Selected Scene: \(selectedScene)")
        var sceneID = String()
        if let hueResults = hueResults{
            for scene in hueResults.scenes{
                if scene.value.name == selectedScene{
                    sceneID = scene.key
                }
            }
        }
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/groups/\(groupNumber)/action") else {return}
        print(url)
        let httpBody = [
            "scene": sceneID
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
    


     func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
         let edit = self.edit(indexPath: indexPath)
         let swipe = UISwipeActionsConfiguration(actions: [edit])
         return swipe
     }
    func edit(indexPath: IndexPath) -> UIContextualAction {
        
         let action = UIContextualAction(style: .normal, title: "Edit") { (_, _, _) in
             print("Take user to edit scene")
            DispatchQueue.main.async {
//                    let editScene = EditSceneVC(sceneName: self.filtered[indexPath.row],
//                                                sourceItems: self.lightsInGroup,
//                                                hueResults: delegate.hueResults,
//                                                bridgeIP: delegate.bridgeIP,
//                                                bridgeUser: delegate.bridgeUser)
                let editScene = EditSceneVC(sceneName: self.sceneArray[indexPath.row].name, groupNumber: self.groupNumber, lightsInGroup: self.lightsInGroup)
                editScene.delegate = self
//                self.sourceItems = self.lightsInGroup
                self.navigationController?.pushViewController(editScene, animated: true)
                
            }
         }
         return action
     }
}
