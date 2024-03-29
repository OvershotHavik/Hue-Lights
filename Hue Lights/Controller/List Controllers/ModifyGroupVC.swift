//
//  ModifyGroupVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/13/20.
//

import UIKit
protocol SelectedGroupDelegate: AnyObject {
    func selectedGroup(group: HueModel.Groups?)
}

class ModifyGroupVC: ListController{
    weak var selectedGroupDelegate : SelectedGroupDelegate?
    fileprivate var originalAllGroups : [HueModel.Groups] // used for search
    fileprivate var allGroups: [HueModel.Groups]
    fileprivate var selectedGroup: HueModel.Groups?
    fileprivate var initialGroup : HueModel.Groups?
    init(allGroups: [HueModel.Groups], selectedGroup: HueModel.Groups?) {
        self.allGroups = allGroups
        self.originalAllGroups = allGroups
        self.selectedGroup = selectedGroup
        self.initialGroup = selectedGroup
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        allGroups = allGroups.sorted(by: { $0.name < $1.name})
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
    
    //MARK: - view will disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        selectedGroupDelegate?.selectedGroup(group: selectedGroup)
    }
    //MARK: - Number Of Rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allGroups.count
    }
    //MARK: - Cell For Row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! ListCell
        cell.accessoryType = .none
        cell.backgroundColor = .systemBackground
        let itemRow = allGroups[indexPath.row]
        if let safeSelectedGroup = selectedGroup{
            if safeSelectedGroup == itemRow{
                cell.accessoryType = .checkmark
            }
        }
        cell.lblListItem.text = itemRow.name
        return cell
    }
    //MARK: - Did Select Row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedVal = allGroups[indexPath.row]
        if let safeSelectedGroup = selectedGroup{
            if safeSelectedGroup == selectedVal{ // user unchecked the group
                selectedGroup = nil
                tableView.cellForRow(at: indexPath)?.accessoryType = .none
            } else {
                Alert.showBasic(title: "There can only be One.", message: "Hue lights can only be in one group. ", vc: self)
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }
        } else { // first time a group is set
            selectedGroup = selectedVal
            print("Group \(selectedVal.name) selected")
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
//MARK: - Search Bar Delegate
extension ModifyGroupVC: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        allGroups = originalAllGroups.sorted(by: {$0.name < $1.name})
        tableView.reloadData()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchText = searchText.lowercased()
        searchBar.text = searchText
        let filtered = allGroups.filter( {$0.name.contains(searchText) })
        self.allGroups = filtered.isEmpty ? [] : filtered
        if searchText == ""{
            self.allGroups = originalAllGroups.sorted(by: {$0.name < $1.name})
        }
        tableView.reloadData()
    }
}
