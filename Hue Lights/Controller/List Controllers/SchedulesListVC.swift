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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scheduleArray = scheduleArray.sorted(by: { $0.name < $1.name})
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
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scheduleArray.count
    }
    
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
        /*
        guard let url = URL(string: baseURL + HueSender.schedules.rawValue + "/\(scheduleID)") else {return}
//        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/schedules/\(scheduleNumber)") else {return}
        print(url)
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
            */
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
}
