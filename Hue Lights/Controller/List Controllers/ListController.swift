//
//  ListController.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/19/20.
//

import UIKit
protocol UpdateLights: class {
    func updateLightsDS(items: [HueModel.Light])
}
protocol UpdateGroups : class{
    func updateGroupsDS(items: [HueModel.Groups])
}
protocol UpdateScenes: class {
    func updateScenesDS(items: [HueModel.Scenes])
}
protocol UpdateSchedules: class {
    func updateScheduleDS(items: [HueModel.Schedules])
}

class ListController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    lazy var noAlertOnSuccessClosure : (Result<String, NetworkError>) -> Void = {Result in
        DispatchQueue.main.async {
            switch Result{
            case .success(let response):
                if response.contains("success"){
                    //don't display an alert if successful
                } else {
                    Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                }
            case .failure(let e): print("Error occured: \(e)")
            }
        }
    }
    lazy var alertClosure : (Result<String, NetworkError>, _ message: String) -> Void = {Result, message  in
        DispatchQueue.main.async {
            switch Result{
            case .success(let response):
                if response.contains("success"){
                    Alert.showBasic(title: "Success", message: message, vc: self)
                } else {
                    Alert.showBasic(title: "Erorr occured", message: response, vc: self) // will need changed later
                }
            case .failure(let e): print("Error occured: \(e)")
            }
        }
    }


    private var filtered = [String]()
    var pickedColor = UIColor.systemBlue
    var colorPicker = UIColorPickerViewController()
    var tempChangeColorButton : UIButton? // used to update the color of the cell's button

    var tableView : UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = 80
        tableView.backgroundColor = .clear
        return tableView
    }()
    fileprivate var hueLights = [HueModel]()

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
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //being overridden in sub classess
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //being overridden in sub classess
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
//        print("test: \(viewController)")
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
