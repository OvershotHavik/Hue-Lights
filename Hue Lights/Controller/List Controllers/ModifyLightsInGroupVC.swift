//
//  ModifyGroupList.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/28/20.
//

import UIKit

protocol SelectedLightsDelegate: class{
    func selectedLights(lights: [HueModel.Light])
}

class ModifyLightsInGroupVC: ListController{
    weak var selectedItemsDelegate : SelectedLightsDelegate?
    fileprivate var originalLightsArray: [HueModel.Light] // used for search
    fileprivate var lightsArray: [HueModel.Light]
    fileprivate var selectedItems : [HueModel.Light]
    fileprivate var limit: Int
    init(limit: Int, selectedItems: [HueModel.Light], lightsArray: [HueModel.Light]){
        self.limit = limit
        self.selectedItems = selectedItems
        self.lightsArray = lightsArray
        self.originalLightsArray = lightsArray
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lightsArray = lightsArray.sorted(by: { $0.name < $1.name})
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
        selectedItemsDelegate?.selectedLights(lights: selectedItems)
    }
    //MARK: - Number Of Rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lightsArray.count
    }
    //MARK: - Cell For Row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! ListCell
        cell.accessoryType = .none
        cell.backgroundColor = .systemBackground
        let itemRow = lightsArray[indexPath.row]
        if selectedItems.contains(itemRow){
            cell.accessoryType = .checkmark
        }
        cell.lblListItem.text = itemRow.name
        return cell
    }
    //MARK: - Did Select Row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedVal = lightsArray[indexPath.row]
        if selectedItems.count <= limit{
            if selectedItems.count == limit{
                if let item = selectedItems.firstIndex(of: selectedVal){
                    selectedItems.remove(at: item)
                    tableView.cellForRow(at: indexPath)?.accessoryType = .none
                    print("Removed \(selectedVal.name) in limit reached ")
                } else {
                    Alert.showBasic(title: "There can only be One.", message: "Hue lights can only be in one group. ", vc: self)
                }
            } else {
                if let item = selectedItems.firstIndex(of: selectedVal){
                    selectedItems.remove(at: item)
                    tableView.cellForRow(at: indexPath)?.accessoryType = .none
                    print("Removed \(selectedVal.name)")
                } else {
                    selectedItems.append(selectedVal)
                    tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
//MARK: - UISearchbar Delegate
extension ModifyLightsInGroupVC: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        lightsArray = originalLightsArray.sorted(by: {$0.name < $1.name})
        tableView.reloadData()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchText = searchText.lowercased()
        searchBar.text = searchText
        let filtered = lightsArray.filter( {$0.name.contains(searchText) })
        self.lightsArray = filtered.isEmpty ? [] : filtered
        if searchText == ""{
            self.lightsArray = originalLightsArray.sorted(by: {$0.name < $1.name})
        }
        tableView.reloadData()
    }
}
