//
//  EditScheduleVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 1/6/21.
//

import UIKit

class EditScheduleVC: UIViewController {
    weak var updateScheduleListDelegate : UpdateSchedules?
    lazy var noAlertOnSuccessClosure : (Result<String, NetworkError>) -> Void = {Result in
        DispatchQueue.main.async {
            switch Result{
            case .success(let response):
                if response.contains("success"){
                    //don't display an alert if successful
                } else {
                    Alert.showBasic(title: "Error occurred", message: response, vc: self) // will need changed later
                }
            case .failure(let e): print("Error occurred: \(e)")
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
                    Alert.showBasic(title: "Error occurred", message: response, vc: self) // will need changed later
                }
            case .failure(let e): print("Error occurred: \(e)")
            }
        }
    }
    fileprivate var rootView : EditScheduleView!
    fileprivate var groupListView : GroupsListVC!
    fileprivate var lightListView : LightsListVC!
    fileprivate var schedule: HueModel.Schedules?
    fileprivate var baseURL: String
    fileprivate var groupsArray : [HueModel.Groups]?
    fileprivate var selectedGroup : HueModel.Groups?
    fileprivate var selectedLight : HueModel.Light?
    fileprivate var recurringSelected = false
    fileprivate var selectedTime : Date?
    fileprivate var appOwner: String
    fileprivate var isOn: Bool? // only include in the schedule if changed by user
    fileprivate var briValue: Int? // only include in the schedule if changed by user
    fileprivate var pickedColor: UIColor? // only include in the schedule if changed by user
    fileprivate var colorPicker = UIColorPickerViewController()
    fileprivate var tempChangeColorButton : UIButton? // used to update the color of the cell's button
    fileprivate var alertSelected : scheduleConstants?
    fileprivate var autoDelete: Bool?
    fileprivate var scheduleType: ScheduleChoices?
    init(baseURL: String, appOwner: String, schedule: HueModel.Schedules?) {
        self.baseURL = baseURL
        self.appOwner = appOwner
        self.schedule = schedule
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func loadView() {
        super.loadView()
        rootView = EditScheduleView(schedule: schedule)
        rootView.scheduleDelegate = self
        colorPicker.delegate = self
        getSelection()
        self.view = rootView
    }
    override func viewWillDisappear(_ animated: Bool) {
        updateScheduleList()
    }
    //MARK: - Update Schedule List
    func updateScheduleList(){
        DataManager.get(baseURL: baseURL,
                        HueSender: .schedules) { results in
            switch results{
            case .success(let data):
                do {
                    let schedulesFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Schedules>.self, from: data)
                    let schedules = schedulesFromBridge.compactMap {$0}.sorted(by: {$0.name < $1.name})
                    for i in schedules{
                        print("Schedule name: \(i.name)")
                    }
                    self.updateScheduleListDelegate?.updateScheduleDS(items: schedules)
                } catch let e {
                    print("Error getting schedules: \(e)")
                }

            case .failure(let e): print(e)
            }
        }
    }
    //MARK: - Get Groups
    func getGroups(){
        DataManager.get(baseURL: baseURL,
                        HueSender: .groups) { results in
            switch results{
            case .success(let data):
                do {
                    let groupsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Groups>.self, from: data)
                    self.groupsArray = groupsFromBridge.compactMap{$0}
                    if let safeGroupsArray = self.groupsArray{
                        DispatchQueue.main.async {
                            let selectGroup = ModifyGroupVC(allGroups: safeGroupsArray, selectedGroup: self.selectedGroup)
                            selectGroup.selectedGroupDelegate = self
                            self.navigationController?.pushViewController(selectGroup, animated: true)
                        }
                    }
                } catch let e {
                    print("Error getting Groups: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
    }
    func getLights(){
        DataManager.get(baseURL: baseURL, HueSender: .lights) { results in
            switch results{
            case .success(let data):
                do {
                    let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                    let lights = lightsFromBridge.compactMap{ $0}

                    DispatchQueue.main.async {
                        if let safeSelectedLight = self.selectedLight {
                            let selectedLightArray = [safeSelectedLight]
                            let lightsListVC = ModifyLightsInGroupVC(limit: 1,
                                                                     selectedItems: selectedLightArray,
                                                                     lightsArray: lights)
                            lightsListVC.selectedItemsDelegate = self
                            self.navigationController?.pushViewController(lightsListVC, animated: true)
                        } else {
                            let lightsListVC = ModifyLightsInGroupVC(limit: 1,
                                                                     selectedItems: [],
                                                                     lightsArray: lights)
                            lightsListVC.selectedItemsDelegate = self
                            self.navigationController?.pushViewController(lightsListVC, animated: true)
                        }
                    }
                } catch let e {
                    print("Error getting lights: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
    }
    //MARK: - Get Selection
    func getSelection(){
        guard let schedule = self.schedule else {return}
        let address = schedule.command.address
        print(address)
        if address.contains(HueSender.groups.rawValue){
            print("fetch group")
            let beforeID = "/api/\(appOwner)/\(HueSender.groups.rawValue)/"
            let shortenedAddress = address.replacingOccurrences(of: beforeID, with: "")
            let groupID = shortenedAddress.replacingOccurrences(of: Destination.action.rawValue, with: "")
            print("Group ID: \(groupID)")
            DataManager.get(baseURL: baseURL,
                            HueSender: .groups) { results in
                switch results{
                case .success(let data):
                    do {
                        let groupsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Groups>.self, from: data)
                        let groups = groupsFromBridge.compactMap{$0}
                        let filtered = groups.filter({$0.id == groupID})
                        for group in filtered{
                            print(group.name)
                        }
                        self.rootView.updateGroupSelected(groupSelected: true)
                        self.rootView.updateSelectionArray(array: filtered)
                    } catch let e {
                        print("Error getting Groups: \(e)")
                    }

                case .failure(let e): print(e)
                    
                }
            }
        }
        if address.contains(HueSender.lights.rawValue){
            print("Fetch light")
            let beforeID = "/api/\(appOwner)/\(HueSender.lights.rawValue)/"
            let shortenedAddress = address.replacingOccurrences(of: beforeID, with: "")
            let lightID = shortenedAddress.replacingOccurrences(of: Destination.state.rawValue, with: "")
            print("Light ID: \(lightID)")
            DataManager.get(baseURL: baseURL, HueSender: .lights) { results in
                switch results{
                case .success(let data):
                    do {
                        let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                        let lights = lightsFromBridge.compactMap{ $0}
                        let filtered = lights.filter({$0.id == lightID})
                        self.rootView.updateGroupSelected(groupSelected: false)
                        self.rootView.updateSelectionArray(array: filtered)

                    } catch let e {
                        print("Error getting lights: \(e)")
                    }
                case .failure(let e): print(e)
                }
            }
        }
    }
}

//MARK: - Schedule Delegate
extension EditScheduleVC: ScheduleDelegate{

    

    
    func autoDeleteToggled(autoDelete: Bool) {
        self.autoDelete = autoDelete
    }
    
    func deleteTapped(name: String) {
        print("Delete tapped, in VC")
        Alert.showConfirmDelete(title: "Delete Schedule", message: "Are you sure you want to delete \(name)?", vc: self) {
            print("Delete pressed.")
            if let safeSchedule = self.schedule{
                DataManager.updateSchedule(baseURL: self.baseURL,
                                           scheduleID: safeSchedule.id,
                                           method: .delete,
                                           httpBody: [:]) { Results in
                    self.alertClosure(Results, "Successfully Deleted \(safeSchedule.name)")
                }
            }
        }
    }
    
    func onToggle(sender: UISwitch) {
        self.isOn = sender.isOn
    }
    
    func changeColor(sender: UIButton) {
        if let safeColor = sender.backgroundColor{
            self.pickedColor = safeColor
        }
        selectColor()
        tempChangeColorButton = sender
    }
    
    func briChanged(sender: UISlider) {
        self.briValue = Int(sender.value)
    }
    
    func flashSelected(flash: scheduleConstants?) {
        self.alertSelected = flash
    }
    
    func recurringToggled(isOn: Bool) {
        print("recurring in vc: \(isOn)")
        self.recurringSelected = isOn
        if isOn == true{
            self.autoDelete = false
        }
    }
    
    func selectGroupTapped() {
        print("in vc")
        getGroups()
    }
    
    func selectLightTapped() {
        print("in vc")
        getLights()
    }
    func timeSelected(time: Date, scheduleType: ScheduleChoices?) {
        print("Time in vc: \(time)")
        self.selectedTime = time
        self.scheduleType = scheduleType
    }
    func saveTapped(name: String, desc: String) {
        //MARK: - Address
        var address = ""
        if let safeSchedule = schedule { // if schedule exist then use the pre existing. Change it below if user modified it
            address = safeSchedule.command.address
        }
        if let selectedGroup = self.selectedGroup{
            address = "/api/\(appOwner)/groups/\(selectedGroup.id)/action"
        }
        if let selectedLight = self.selectedLight{
            address = "/api/\(appOwner)/lights/\(selectedLight.id)/state"
        }
        print("Address: \(address)")
        //MARK: - xy
        var xy : [Double]?
        if let pickedColor = self.pickedColor{
            if let tempChangeColorButton = tempChangeColorButton{
                tempChangeColorButton.backgroundColor = pickedColor
                let red = pickedColor.components.red
                let green = pickedColor.components.green
                let blue = pickedColor.components.blue
                let colorXY = ConvertColor.getXY(red: red, green: green, blue: blue)
                xy = colorXY
            }
        }
        
        //MARK: - Time
        guard let selectedTime = self.selectedTime else {
            print("Select a time")
            return}

        var time = ""
        
        switch scheduleType{
        case .timer : print("Do something for timer")
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let formattedTime = formatter.string(from: selectedTime)
            if recurringSelected == true{
                time = Time.recurring.rawValue + formattedTime
//                time = "\(Time.recurring.rawValue)\(formattedTime)"
                self.autoDelete = nil // if recurring is selected, auto delete needs to be nil
            } else {
                time = Time.timer.rawValue + formattedTime
//                time = "\(Time.timer.rawValue)\(formattedTime)"
            }
        case .selectTime: print("Do something for time")
            let formatter = DateFormatter()
            formatter.dateFormat = "YYYY-MM-DD'T'HH:mm:ss"
            let formattedTime = formatter.string(from: selectedTime)
            time = formattedTime
        default: print("Not setup in time selected in VC")
        }

        //MARK: - Create Struct
        let body = HueModel.Body(scene: nil,
                                 status: nil,
                                 alert: self.alertSelected?.rawValue,
                                 bri: self.briValue,
                                 on: self.isOn,
                                 xy: xy)
        let command = HueModel.Command(address: address,
                                       body: body,
                                       method: "PUT")
        
        let newSchedule = CreateSchedule(name: name,
                                         description: desc,
                                         command: command,
                                         localtime: time,
                                         autodelete: self.autoDelete)
        //MARK: - Encode and send to bridge
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .withoutEscapingSlashes
            let newScheduleData = try encoder.encode(newSchedule)

            let scheduleString = String(data: newScheduleData, encoding: .utf8) ?? ""
            print(scheduleString)
            if let safeSchedule = schedule{
                DataManager.modifySchedule(baseURL: baseURL,
                                           scheduleID: safeSchedule.id,
                                           newScheduleData: newScheduleData) { Results in
                    self.alertClosure(Results, "Successfully updated \(name)")
                }
            } else {
                DataManager.createNewSchedule(baseURL: baseURL,
                                              scheduleData: newScheduleData) { results in
                    self.alertClosure(results, "Successfully created schedule: \(name)")
                }

 
            }
 
        } catch let e{
            print(e)
        }
    }

}

//MARK: - SelectedGroupDelegate
extension EditScheduleVC: SelectedGroupDelegate{
    func selectedGroup(group: HueModel.Groups?) {
        self.selectedGroup = group
        
        if let safeSelectedGroup = self.selectedGroup{
            rootView.updateSelectionArray(array: [safeSelectedGroup])
        }

    }

    
}
extension EditScheduleVC : UIColorPickerViewControllerDelegate{
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        pickedColor = viewController.selectedColor
        guard let tempChangeColorButton = tempChangeColorButton else {return}
        tempChangeColorButton.backgroundColor = pickedColor
//        updateLightColor()
    }
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        print("color picker controler did finish")
    }
    func selectColor(){
        colorPicker.supportsAlpha = false
        colorPicker.selectedColor = pickedColor ?? UIColor()
        self.present(colorPicker, animated: true)
    }
    func updateLightColor(){
        guard let tempChangeColorButton = tempChangeColorButton else {return}
        guard let pickedColor = self.pickedColor else {return}
        tempChangeColorButton.backgroundColor = pickedColor
        let red = pickedColor.components.red
        let green = pickedColor.components.green
        let blue = pickedColor.components.blue
        let colorXY = ConvertColor.getXY(red: red, green: green, blue: blue)
        let lightID = String(tempChangeColorButton.tag)
        let httpBody = [Keys.xy.rawValue: colorXY]
        DataManager.updateLight(baseURL: baseURL,
                                lightID: lightID,
                                method: .put,
                                httpBody: httpBody,
                                completionHandler: noAlertOnSuccessClosure)
    }
}

extension EditScheduleVC: SelectedLightsDelegate{
    func selectedLights(lights: [HueModel.Light]) {
        if let selected = lights.first{
            self.selectedLight = selected
            rootView.updateSelectionArray(array: [selected])
        }
        
    }
    
    
}
