//
//  ListController.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/19/20.
//

import UIKit
protocol ListSelectionControllerDelegate : class {
    var sourceItems : [String] {get}
//    var hueLights : [HueModel.Light] {get}
    var hueResults : [HueModel] {get}
    var bridgeIP : String {get}
    var bridgeUser: String {get}
}
protocol UpdateList : class{
    func updateList(items: [String])
}
class ListController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    weak var delegate: ListSelectionControllerDelegate?
    private var filtered = [String]()
    var pickedColor = UIColor.systemBlue
    var colorPicker = UIColorPickerViewController()
    var tempChangeColorButton : UIButton? // used to update the color of the cell's button

    lazy var tableView : UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
//        tableView.allowsSelection = false
        tableView.register(HueLightsCell.self, forCellReuseIdentifier: Cells.cell)
        tableView.backgroundColor = .none
        return tableView
    }()
    fileprivate var hueLights = [HueModel]()
    struct Cells {
        static let cell = "HueLightsCell"
    }

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



//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        colorPicker.delegate = self
        searchController.searchBar.isTranslucent = false
        navigationItem.searchController = searchController
//        searchController.searchBar.delegate = self
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
        self.view.backgroundColor = .systemBlue
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
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filtered.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        return cell
    }
    func updatLightColor(){
        //being overriden in sub classess
    }
}

//MARK: - Color picker
extension ListController : UIColorPickerViewControllerDelegate{
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        pickedColor = viewController.selectedColor
        updatLightColor()
    }
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        print("color picker controler did finish")
    }
    func selectColor(){
        colorPicker.supportsAlpha = false
        colorPicker.selectedColor = pickedColor
        self.present(colorPicker, animated: true)
    }
}