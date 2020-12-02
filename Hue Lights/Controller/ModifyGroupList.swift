//
//  ModifyGroupList.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/28/20.
//

import UIKit

protocol SelectedItems: class{
    func setSelectedItems(items: [String], ID: String)
}
class ModifyGroupList: ListController{
    weak var selectedItemsDelegate : SelectedItems?
    fileprivate var filtered = [String]()
    fileprivate var selectedItems : [String]
    fileprivate var limit: Int
    init(limit: Int, selectedItems: [String]){
        self.limit = limit
        self.selectedItems = selectedItems
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let delegate = delegate else {
            assertionFailure("Set the delegate")
            return
        }
        filtered = delegate.sourceItems.sorted(by: { $0.lowercased() < $1.lowercased()})
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
    //MARK: - view will disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        if let safeID = ID{
            selectedItemsDelegate?.setSelectedItems(items: selectedItems, ID: "")
//        }
        selectedItems = []
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! ListCell
        cell.accessoryType = .none
        cell.backgroundColor = .systemBackground
        let itemRow = filtered[indexPath.row]
        if selectedItems.contains(itemRow){
            cell.accessoryType = .checkmark
        }
        cell.lblListItem.text = itemRow
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        let selectedVal = filtered[indexPath.row]
        if selectedItems.count <= limit{
            if selectedItems.count == limit{
                if let item = selectedItems.firstIndex(of: selectedVal){
                    selectedItems.remove(at: item)
                    tableView.cellForRow(at: indexPath)?.accessoryType = .none
                    print("Removed \(selectedVal) in limit reached ")
                } else {
                    Alert.showBasic(title: "There can only be One.", message: "Hue lights can only be in one group. ", vc: self)
                }
            } else {
                if let item = selectedItems.firstIndex(of: selectedVal){
                    selectedItems.remove(at: item)
                    tableView.cellForRow(at: indexPath)?.accessoryType = .none
                    print("Removed \(selectedVal)")
                } else {
                    selectedItems.append(selectedVal)
                    tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                }
            }
        }
        print("Selected items: \(selectedItems)")
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
//MARK: - UISearchbar Delegate
extension ModifyGroupList: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        guard let delegate = delegate else {
            assertionFailure("Set the delegate bitch")
            return
        }
        filtered = delegate.sourceItems.sorted(by: { $0.lowercased() < $1.lowercased()})
        tableView.reloadData()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchText = searchText.lowercased()
        searchBar.text = searchText
        guard let delegate = delegate else {
            assertionFailure("Set the delegate")
            return
        }
        let filtered = delegate.sourceItems.filter( {$0.lowercased().contains(searchText) })
        self.filtered = filtered.isEmpty ? [] : filtered
        tableView.reloadData()
    }
}



