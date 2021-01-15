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
    fileprivate var appOwner: String
    init(baseURL: String, appOwner: String, scheduleArray: [HueModel.Schedules]) {
        self.baseURL = baseURL
        self.appOwner = appOwner
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addSchedule))
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
        if itemRow.status == Constants.disabled.rawValue{
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
        
        //Check to see if the time is in the past, if it is the update it to today/future
        let scheduleID = String(sender.tag)
        let filtered = scheduleArray.filter({$0.id == scheduleID})
        if let selected = filtered.first{
            if let safeTime = selected.localtime{
                let now = Date()
                print("selected: \(selected.name)")
                let formatter = DateFormatter()
                formatter.dateFormat = "YYYY-MM-DD'T'HH:mm:ss"
                //Below only runs if user selected a time but didn't select to happen on a specific day of the week
                if var selectedDate = formatter.date(from: safeTime){
                    while selectedDate < now{
                        print("Selected Date: \(selectedDate)")
                        print("Time is in the past.. change to be today/future")
                        selectedDate.addTimeInterval(60 * 60 * 24) // add 24 hours in seconds to the date and check again
                    }
                    print("selected date is now in the future, send the updated time to the bridge for this schedule, then activate it ")
                     let updatedDateStr = formatter.string(from: selectedDate)
                    
                    let httpBody = [Keys.localtime.rawValue: updatedDateStr]
                    DataManager.updateSchedule(baseURL: baseURL,
                                               scheduleID: scheduleID,
                                               method: .put,
                                               httpBody: httpBody,
                                               completionHandler: self.noAlertOnSuccessClosure)
                }
            }
        }
        print("sender tag: \(sender.tag)")
        var httpBody = [String: String]()
        if sender.isOn == true{
            httpBody[Keys.status.rawValue] = Constants.enabled.rawValue
        } else {
            httpBody[Keys.status.rawValue] = Constants.disabled.rawValue
        }
        DataManager.updateSchedule(baseURL: baseURL,
                                   scheduleID: scheduleID,
                                   method: .put,
                                   httpBody: httpBody,
                                   completionHandler: self.noAlertOnSuccessClosure)
        }
    @objc func addSchedule(){
        let editScheduleVC = EditScheduleVC(baseURL: baseURL, appOwner: appOwner, schedule: nil)
        self.navigationController?.pushViewController(editScheduleVC, animated: true)
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
    //MARK: - Trailing Swipe Action - Delete
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            let schedule = scheduleArray[indexPath.row]
            if editingStyle == .delete{
                Alert.showConfirmDelete(title: "Delete Scene?", message: "Are you sure you want to delete \(schedule.name)?", vc: self) {
                    print("Delete pressed")
                    DataManager.updateSchedule(baseURL: self.baseURL,
                                               scheduleID: schedule.id,
                                               method: .delete,
                                               httpBody: [:]) { results in
                        self.alertClosure(results, "Successfully deleted \(schedule.name).")
                    }
                    self.scheduleArray.remove(at: indexPath.row)
                    self.tableView.reloadData()
                }
            }
        }
    
    
    //MARK: - Leading Swipe Action
         func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            let schedule = self.scheduleArray[indexPath.row]
            if schedule.command.address.contains(self.appOwner){
                let edit = self.edit(indexPath: indexPath)
                let swipe = UISwipeActionsConfiguration(actions: [edit])
                return swipe
            }
            return UISwipeActionsConfiguration()
         }
    //MARK: - Leading Swipe Action - Edit
        func edit(indexPath: IndexPath) -> UIContextualAction {
            let action = UIContextualAction(style: .normal, title: "Edit") { (_, _, _) in
                print("Take user to edit schedule")
                let schedule = self.scheduleArray[indexPath.row]
                let editScheduleVC = EditScheduleVC(baseURL: self.baseURL,
                                                    appOwner: self.appOwner,
                                                    schedule: schedule)
                editScheduleVC.updateScheduleListDelegate = self
                self.navigationController?.pushViewController(editScheduleVC, animated: true)
                
            }
            return action
         }
 
}
//MARK: - Update Schedules
extension ScheduleListVC: UpdateSchedules{
    func updateScheduleDS(items: [HueModel.Schedules]) {
        DispatchQueue.main.async {
            self.scheduleArray = items
            self.tableView.reloadData()
        }
    }
    
    
}
