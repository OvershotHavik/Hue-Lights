//
//  SceneListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/2/20.
//

import UIKit

class SceneListVC: ListController{
    fileprivate var filtered = [String]()
    fileprivate var sceneArray = [HueModel.Scenes]()
    fileprivate var hueResults = [HueModel]()
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        setup()
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
//        searchController.searchBar.delegate = self
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
//        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/scenes/\(sceneID)/state") else {return}
//        url will need corrected for the scene api
//        enable the scene when user clicks the row
    }
}
