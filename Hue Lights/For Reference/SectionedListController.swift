//
//  SectionedListController.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/25/20.
//

/*
 
 
setup to have the lights and groups in one big table view instead of seperate. Issue with this one is that the commands to change the color/brightness change depending if it's going to a specific light or to gorups, and the table view gets messy when the cells don't update correctly
 
import UIKit
protocol ListSelectionControllerDelegate : class {
//    var sourceItems : [String] {get}
//    var hueLights : [HueModel.Light] {get}
    var hueResults : [HueModel] {get}
    var bridgeIP : String {get}
    var bridgeUser: String {get}
//    func setSelectedItems(_ item: String, ID: ID)
}
protocol UpdateList : class{
    func updateList(items: [String])
}

enum Headers: String{
    case groups = "Groups"
    case lights = "Lights"
}

class ListData{
    var source: Headers
    var names: [String]
    var isExpanded: Bool
    init (source: Headers, names: [String], isExpanded: Bool = true) { // change to false later
        self.source = source
        self.names = names
        self.isExpanded = isExpanded
    }
}


class ListController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    weak var delegate: ListSelectionControllerDelegate?
    private var listDataArray = [ListData]()
    private var filtered = [String]()
    private var hueGroups = [HueModel.Groups]()
    private var hueLights = [HueModel.Light]()
    private var hueResults = [HueModel]()
    private var pickedColor = UIColor.systemBlue
    private var colorPicker = UIColorPickerViewController()
    private var tempChangeColorButton : UIButton? // used to update the color of the cell's button

    lazy var tableView : UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        tableView.allowsSelection = false
        tableView.register(HueLightsCell.self, forCellReuseIdentifier: Cells.cell)
        tableView.backgroundColor = .none
        return tableView
    }()
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
        searchController.searchBar.delegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        populateTable()

//        self.tableView.reloadData()
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
    
    //MARK: - Populate Table
    
    func populateTable(){
        guard let delegate = delegate else {
            assertionFailure("Set the delegate")
            return
        }
//        filtered = delegate.sourceItems.sorted(by: { $0.lowercased() < $1.lowercased()})
        hueResults = delegate.hueResults
        var lightNames = [String]()
        var groupNames = [String]()
        for x in hueResults{
            for light in x.lights{
                hueLights.append(light.value)
                lightNames.append(light.value.name)
            }
            for group in x.groups{
                hueGroups.append(group.value)
                groupNames.append(group.value.name)
            }
        }
        listDataArray.append(ListData(source: Headers.groups, names: groupNames, isExpanded: true))
        listDataArray.append(ListData(source: Headers.lights, names: lightNames, isExpanded: true))
        self.tableView.reloadData()

//        filtered = lightNames.sorted(by: {$0.lowercased() < $1.lowercased()})
    }
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return listDataArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return listDataArray[section].source.rawValue
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if listDataArray[section].isExpanded == false{
            return 0
        }
        return listDataArray[section].names.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        switch listDataArray[indexPath.section].source{
        case .groups:
            let rowName = listDataArray[indexPath.section].names[indexPath.row]
            let filtered = hueGroups.filter({$0.name == rowName})
            for group in filtered{
                let reachable = group.state.any_on
                let cellData = LightData(lightName: group.name,
                                         isOn: group.state.all_on,
                                         brightness: Float(group.action.bri),
                                         isReachable: reachable,
                                         lightColor: ConvertColor.getRGB(xy: group.action.xy, bri: group.action.bri))
                cell.configureCell(LightData: cellData)
                for x in hueResults{
                    for i in x.lights{
                        if i.value.name == group.name{
                            if let tag = Int(i.key){
                                cell.onSwitch.tag = tag
                                cell.brightnessSlider.tag = tag
                                cell.btnChangeColor.tag = tag
        //                        print("tag: \(onSwitch.tag)")
                            }
                        }
                    }
                }
            }
        case .lights:
            //        let lightRow = listDataArray[indexPath.section].names[indexPath.row]
            
            
            //        let rowName = filtered[indexPath.row]
            let rowName = listDataArray[indexPath.section].names[indexPath.row]
            let filtered = hueLights.filter({$0.name == rowName})
            for light in filtered{
                let reachable = light.state.reachable
                let cellData = LightData(lightName: light.name,
                                         isOn: light.state.on,
                                         brightness: Float(light.state.bri),
                                         isReachable: reachable,
                                         lightColor: ConvertColor.getRGB(xy: light.state.xy, bri: light.state.bri))
                cell.configureCell(LightData: cellData)
                for x in hueResults{
                    for i in x.lights{
                        if i.value.name == light.name{
                            if let tag = Int(i.key){
                                cell.onSwitch.tag = tag
                                cell.brightnessSlider.tag = tag
                                cell.btnChangeColor.tag = tag
                                //                        print("tag: \(onSwitch.tag)")
                            }
                        }
                    }
                }
            }
        }
        cell.backgroundColor = .clear
        return cell
    }
}

extension ListController: UISearchBarDelegate{
    
}


//MARK: - HueCellDelegate
extension ListController: HueCellDelegate{
    
    
    func onSwitchToggled(sender: UISwitch) {
        guard let delegate = delegate else { return}
        print("Sender's Tag: \(sender.tag)")
        let lightNumber = sender.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/lights/\(lightNumber)/state") else {return}
        print(url)
        let httpBody = [
            "on": sender.isOn,
        ]
        DataManager.put(url: url, httpBody: httpBody)
    }
    
    func brightnessSliderChanged(sender: UISlider) {
        guard let delegate = delegate else { return}
        print("Brightness slider changed")
        print("Sender's Tag: \(sender.tag)")
        
        let lightNumber = sender.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/lights/\(lightNumber)/state") else {return}
        print(url)
        let httpBody = [
            "bri": Int(sender.value),
        ]
        DataManager.put(url: url, httpBody: httpBody)
        
    }
    func changeLightColor(sender: UIButton) {
        print("change light color tapped")
        selectColor()
        tempChangeColorButton = sender
    }
    
    func updatLightColor(){
        guard let tempChangeColorButton = tempChangeColorButton else {return}
        guard let delegate = delegate else { return}
        tempChangeColorButton.backgroundColor = pickedColor
        let red = pickedColor.components.red
        let green = pickedColor.components.green
        let blue = pickedColor.components.blue
        let colorXY = ConvertColor.getXY(red: red, green: green, blue: blue)
        let lightNumber = tempChangeColorButton.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/lights/\(lightNumber)/state") else {return}
        print(url)
        let httpBody = [
            "xy": colorXY,
        ]
        DataManager.put(url: url, httpBody: httpBody)
    }
}
//MARK: - Color picker
extension ListController : UIColorPickerViewControllerDelegate{
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        pickedColor = viewController.selectedColor
        print("color selected")
        updatLightColor()
    }
 
    /*
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        print("color selected")
    }
 */
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        print("color picker controler did finish")
    }
    private func selectColor(){
        colorPicker.supportsAlpha = false
        if let safeColor = tempChangeColorButton?.backgroundColor{
            colorPicker.selectedColor = safeColor
        } else {
            colorPicker.selectedColor = pickedColor
        }
        self.present(colorPicker, animated: true)
    }
}
 */
