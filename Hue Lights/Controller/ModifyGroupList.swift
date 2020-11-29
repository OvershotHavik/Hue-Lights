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

class ModifyGroupList: UIViewController, UITableViewDelegate, UpdateList{
    //    weak var updateDelegate: UpdateList?
    weak var selectedItemsDelegate : SelectedItems?
    weak var delegate : ListSelectionControllerDelegate?
    private var filtered : [String] = []
    private var spinner = UIActivityIndicatorView(style: .large)
    fileprivate var searchText = String()
    fileprivate var tableView = UITableView()
    fileprivate var searchBar = UISearchBar()
    fileprivate var selectedItems : [String]
    fileprivate var ID : String? // modified by fetch data to determine who sent the info, so it can back feed and update fileprivate any labels
    

    init(selectedItems: [String]){
        self.selectedItems = selectedItems
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    struct Cells {
        static let cell = "ItemCell"
    }
    
    private let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchController.searchBar.accessibilityIdentifier = "SearchBar"
        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.sizeToFit()
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.returnKeyType = .done
        return searchController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UI.backgroundColor
        searchController.searchBar.isTranslucent = false
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self
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
    func updateList(items: [String]) {
        filtered = items
        tableView.reloadData()
    }
    //MARK: - setup layout and constrains
    func setup(){
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 50
        tableView.register(ListCell.self, forCellReuseIdentifier: Cells.cell)
        tableView.backgroundColor = .clear
        setupConstraints()
    }
    //MARK: - Setup Constraints
    func setupConstraints(){
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    //MARK: - view will disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        if let safeID = ID{
            selectedItemsDelegate?.setSelectedItems(items: selectedItems, ID: "")
//        }
        selectedItems = []
    }
}

//MARK: - UITableview Delegate and Datasource
extension ModifyGroupList: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filtered.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        if let item = selectedItems.firstIndex(of: selectedVal){
            selectedItems.remove(at: item)
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
            print("Removed \(selectedVal)")
        } else {
            selectedItems.append(selectedVal)
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        }
        print("Selected items: \(selectedItems)")
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




