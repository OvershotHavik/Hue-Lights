//
//  LightsListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/25/20.
//

import UIKit

class LightsListVC: ListController{
//    weak var updateGroupDelegate : UpdateGroups?
    
    var lightsArray : [HueModel.Light]
    fileprivate var originalLightsArray : [HueModel.Light] // used for search
    fileprivate var showingGroup: HueModel.Groups?
    fileprivate var baseURL: String

    init(baseURL: String, lightsArray: [HueModel.Light], showingGroup: HueModel.Groups?) {
        self.baseURL = baseURL
        self.lightsArray = lightsArray
        self.showingGroup = showingGroup
        self.originalLightsArray = lightsArray
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(HueLightsCell.self, forCellReuseIdentifier: Cells.cell) // change the cell depending on which VC is using this
        tableView.delegate = self
        tableView.dataSource = self
        colorPicker.delegate = self
        setup()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addLight))
    }
    
    @objc func addLight(){
        print("Searching for new lights on bridge")
        DataManager.searchForNewLights(baseURL: baseURL) { results in
            self.alertClosure(results, "Searching for new lights. Refresh in 30 seconds")
        }
    }
    //MARK: - View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lightsArray = lightsArray.sorted(by: {$0.name < $1.name })
        self.tableView.reloadData()
        searchController.searchBar.isTranslucent = false
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self    }
    //MARK: - Number of Rows in section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lightsArray.count
    }
    //MARK: - Did Select Row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let light = lightsArray[indexPath.row]
        DispatchQueue.main.async {
            let editLight = EditLightVC(baseURL: self.baseURL, light: light, showingInGroup: self.showingGroup)
            editLight.updateDelegate = self
            self.navigationController?.pushViewController(editLight, animated: true)
        }
    }
    //MARK: - Cell for row at
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        let light = lightsArray[indexPath.row]
        cell.configureLightCell(light: light)
        if let tag = Int(light.id){
            cell.onSwitch.tag = tag
            cell.brightnessSlider.tag = tag
            cell.btnChangeColor.tag = tag
        }
        cell.backgroundColor = .clear
        return cell
    }
    //MARK: - Update Light Color
    override func updateLightColor(){
        guard let tempChangeColorButton = tempChangeColorButton else {return}
        tempChangeColorButton.backgroundColor = pickedColor
        let red = pickedColor.components.red
        let green = pickedColor.components.green
        let blue = pickedColor.components.blue
        let colorXY = ConvertColor.getXY(red: red, green: green, blue: blue)
        let lightID = String(tempChangeColorButton.tag)
        let httpBody = ["xy": colorXY]
        DataManager.updateLight(baseURL: baseURL,
                                lightID: lightID,
                                method: .put,
                                httpBody: httpBody,
                                completionHandler: noAlertOnSuccessClosure)
    }
}
//MARK: - Hue Cell Delegate
extension LightsListVC: HueCellDelegate{
    func onSwitchToggled(sender: UISwitch) {
        print("Sender's Tag: \(sender.tag)")
        let lightID = String(sender.tag)
        let httpBody = ["on": sender.isOn]
        DataManager.updateLight(baseURL: baseURL,
                                lightID: lightID,
                                method: .put,
                                httpBody: httpBody,
                                completionHandler: noAlertOnSuccessClosure)
    }
    //MARK: - Brightness Slider Changed
    func brightnessSliderChanged(sender: UISlider) {
        print("Brightness slider changed")
        print("Sender's Tag: \(sender.tag)")
        let lightID = String(sender.tag)
        let httpBody = ["bri": Int(sender.value)]
        DataManager.updateLight(baseURL: baseURL,
                                lightID: lightID,
                                method: .put,
                                httpBody: httpBody,
                                completionHandler: noAlertOnSuccessClosure)
    }
    //MARK: - Change Light Color
    func changeLightColor(sender: UIButton) {
        print("change light color tapped")
        if let safeColor = sender.backgroundColor{
            pickedColor = safeColor
        }
        selectColor()
        tempChangeColorButton = sender
    }

}
//MARK: - UI Search Bar Delegate
extension LightsListVC: UISearchBarDelegate{
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        lightsArray = originalLightsArray.sorted(by: {$0.name < $1.name})
        tableView.reloadData()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchText = searchText
        searchBar.text = searchText
        print("SearchText: \(searchText)")
        let filtered = lightsArray.filter {$0.name.contains(searchText)}
        self.lightsArray = filtered.isEmpty ? [] : filtered
        if searchText == ""{
            self.lightsArray = originalLightsArray.sorted(by: {$0.name < $1.name})
        }
        tableView.reloadData()
    }
}

//MARK: -  Edit Group
extension LightsListVC : UpdateLights{
    func updateLightsDS(items: [HueModel.Light]) {
        DispatchQueue.main.async {
            self.lightsArray = items.sorted(by: {$0.name < $1.name})
            self.tableView.reloadData()
        }
    }
}
