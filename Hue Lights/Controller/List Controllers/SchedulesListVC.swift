//
//  SchedulesListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/2/20.
//

import UIKit

class ScheduleListVC: ListController{
    fileprivate var scheduleArray : [HueModel.Schedules]
    fileprivate var originalScheduleArray : [HueModel.Schedules] // used for search
    fileprivate var baseURL : String
    init(baseURL: String, scheduleArray: [HueModel.Schedules]) {
        self.baseURL = baseURL
        self.scheduleArray = scheduleArray
        self.originalScheduleArray = scheduleArray
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scheduleArray = scheduleArray.sorted(by: { $0.name < $1.name})
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
        setup()
    }
    //MARK: - number of rows in section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scheduleArray.count
    }
    //MARK: - Cell For Row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! ListCell
        cell.accessoryType = .none
        cell.backgroundColor = .systemBackground
        let itemRow = scheduleArray[indexPath.row]
        cell.lblListItem.text = itemRow.name
        let onSwitch = UISwitch()
        if itemRow.status == "disabled"{
            onSwitch.isOn = false
        } else {
            onSwitch.isOn = true
        }
        if let tag = Int(itemRow.id){
            onSwitch.tag = tag
        }
        onSwitch.addTarget(self, action: #selector(onToggled), for: .valueChanged)
        cell.accessoryView = onSwitch
        return cell
    }
    //MARK: - objc - On Toggled
    @objc func onToggled(sender: UISwitch){
        let scheduleID = String(sender.tag)
        print("sender tag: \(sender.tag)")
        var httpBody = [String: String]()
        if sender.isOn == true{
            httpBody["status"] = "enabled"
        } else {
            httpBody["status"] = "disabled"
        }
        DataManager.updateSchedule(baseURL: baseURL,
                                   scheduleID: scheduleID,
                                   method: .put,
                                   httpBody: httpBody,
                                   completionHandler: self.noAlertOnSuccessClosure)
        }
}
extension ScheduleListVC: UISearchBarDelegate{
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        scheduleArray = originalScheduleArray.sorted(by: {$0.name < $1.name})
        tableView.reloadData()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchText = searchText
        searchBar.text = searchText
        print("SearchText: \(searchText)")
        let filtered = scheduleArray.filter {$0.name.contains(searchText)}
        self.scheduleArray = filtered.isEmpty ? [] : filtered
        if searchText == ""{
            self.scheduleArray = originalScheduleArray.sorted(by: {$0.name < $1.name})
        }
        tableView.reloadData()
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
                print("Take user to edit schedule")
                let schedule = self.scheduleArray[indexPath.row]
                let editScheduleVC = EditScheduleVC(schedule: schedule)
                self.navigationController?.pushViewController(editScheduleVC, animated: true)
                
            }
            return action
         }
}
