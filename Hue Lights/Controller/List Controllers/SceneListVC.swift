//
//  SceneListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/2/20.
//

import UIKit

class SceneListVC: ListController, BridgeInfoDelegate{
    var bridgeIP = String()
    var bridgeUser = String()
    
    fileprivate var sceneArray : [HueModel.Scenes]
    fileprivate var originalSceneArray : [HueModel.Scenes] // used for search
    fileprivate var group: HueModel.Groups?
    fileprivate var lightsInGroup: [HueModel.Light]
    
    
    init(group: HueModel.Groups?, lightsInGroup: [HueModel.Light], sceneArray: [HueModel.Scenes]) {
        self.group = group
        self.lightsInGroup = lightsInGroup
        self.sceneArray = sceneArray
        self.originalSceneArray = sceneArray
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
        sceneArray = sceneArray.sorted(by: { $0.name < $1.name})
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
        if let safeGroup = group{
            let addScene = EditSceneVC(sceneName: "", sceneID: Constants.newScene.rawValue, group: safeGroup, lightsInGroup: lightsInGroup)
            addScene.delegate = self
            self.navigationController?.pushViewController(addScene, animated: true)
        }
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
        if let safeGroup = group{
            let scene = sceneArray[indexPath.row]
            print("Selected Scene: \(scene.name)")
            
            guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/groups/\(safeGroup.id)/action") else {return}
            print(url)
            let httpBody = [
                "scene": scene.id
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
    


     func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
         let edit = self.edit(indexPath: indexPath)
         let swipe = UISwipeActionsConfiguration(actions: [edit])
         return swipe
     }
    func edit(indexPath: IndexPath) -> UIContextualAction {
         let action = UIContextualAction(style: .normal, title: "Edit") { (_, _, _) in
             print("Take user to edit scene")
            DispatchQueue.main.async {
                let selected = self.sceneArray[indexPath.row]
                let name = selected.name
                let id = selected.id
                if let safeGroup = self.group{
                    let editScene = EditSceneVC(sceneName: name,
                                                sceneID: id,
                                                group: safeGroup,
                                                lightsInGroup: self.lightsInGroup)
                    editScene.delegate = self
                    self.navigationController?.pushViewController(editScene, animated: true)
                }
            }
         }
         return action
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
