//
//  SceneListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/2/20.
//

import UIKit

class SceneListVC: ListController, UISearchBarDelegate{
    fileprivate var filtered = [String]()
    fileprivate var sceneArray = [HueModel.Scenes]()
    fileprivate var hueResults = [HueModel]()
    fileprivate var groupNumber: String
    fileprivate var lightsInGroup: [String]
    init(groupNumber: String, lightsInGroup: [String]) {
        self.groupNumber = groupNumber
        self.lightsInGroup = lightsInGroup
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
        filtered = delegate.sourceItems.sorted(by: { $0.lowercased() < $1.lowercased()})
        hueResults = delegate.hueResults
        for x in hueResults{
            sceneArray.append(contentsOf: x.scenes.values)
        }
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
        setup()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! ListCell
        cell.accessoryType = .none
        cell.backgroundColor = .systemBackground
        let itemRow = filtered[indexPath.row]
        cell.lblListItem.text = itemRow
        /*
        var sceneID: String?
        for x in hueResults{
            for scene in x.scenes{
                if scene.value.name == itemRow{
                    sceneID = scene.value.image
                }
            }
        }


        let onSwitch = UISwitch()
        for x in hueResults{
            for schedule in x.schedules{
                if schedule.value.name == itemRow{
                    if schedule.value.status == "disabled"{
                        onSwitch.isOn = false
                    } else {
                        onSwitch.isOn = true
                    }
                    if let tag = Int(schedule.key){
                        onSwitch.tag = tag
                    }
                }
            }
        }
        onSwitch.addTarget(self, action: #selector(onToggled), for: .valueChanged)
        cell.accessoryView = onSwitch
 */
        return cell
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filtered.count
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let delegate = delegate else {
            assertionFailure("Set the delegate")
            return
        }
        print("scene: \(filtered[indexPath.row])")
        let selectedScene = filtered[indexPath.row]
        var sceneID = String()
        for x in hueResults{
            for scene in x.scenes{
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
                if let delegate = self.delegate{
                    let editScene = EditSceneVC(sceneName: self.filtered[indexPath.row],
                                                sourceItems: self.lightsInGroup,
                                                hueResults: delegate.hueResults,
                                                bridgeIP: delegate.bridgeIP,
                                                bridgeUser: delegate.bridgeUser)
                    
                    self.navigationController?.pushViewController(editScene, animated: true)
                }
            }
         }
         return action
     }
}
