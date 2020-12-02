//
//  SchedulesListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/2/20.
//

import UIKit

class ScheduleListVC: UIViewController, UITableViewDelegate, UITableViewDataSource{
    weak var delegate: ListSelectionControllerDelegate?
    private var filtered = [String]()
    
    struct Cells {
        static let cell = "HueLightsCell"
    }
    lazy var tableView : UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
//        tableView.allowsSelection = false
        tableView.register(ListCell.self, forCellReuseIdentifier: Cells.cell)
        tableView.backgroundColor = .clear
        return tableView
    }()
    let searchController: UISearchController = {
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
        searchController.searchBar.isTranslucent = false
        navigationItem.searchController = searchController
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

    
    //MARK: - setup layout and constrains
    func setup(){
        self.view.backgroundColor = UI.backgroundColor
        view.addSubview(tableView)
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
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filtered.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = filtered[indexPath.row]
        return cell
    }
}
