//
//  EditScheduleVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 1/6/21.
//

import UIKit

class EditScheduleVC: UIViewController {
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
    fileprivate var alertSelected = false
    fileprivate var recurringSelected = false
    fileprivate var selectedTime : Date?
    fileprivate var appOwner: String
    fileprivate var isOn: Bool? // only include in the schedule if changed by user
    fileprivate var briValue: Int? // only include in the schedule if changed by user
    fileprivate var pickedColor: UIColor? // only include in the schedule if changed by user
    fileprivate var colorPicker = UIColorPickerViewController()
    fileprivate var tempChangeColorButton : UIButton? // used to update the color of the cell's button

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
        self.view = rootView

    }
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
}

//MARK: - Schedule Delegate
extension EditScheduleVC: ScheduleDelegate{
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
    
    func flashToggled(isOn: Bool) {
        print("flash in vc: \(isOn)")
        self.alertSelected = isOn
    }
    
    func recurringToggled(isOn: Bool) {
        print("recurring in vc: \(isOn)")
        self.recurringSelected = isOn
    }
    
    func selectGroupTapped() {
        print("in vc")
        getGroups()
    }
    
    func selectLightTapped() {
        print("in vc")
    }
    
    func timeSelected(time: Date) {
        print("Time in vc: \(time)")
        self.selectedTime = time
    }
    
    func saveTapped(name: String, desc: String) {
        //MARK: - Address
        var address = ""
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
        //MARK: - Alert
        var alert : String?
        if alertSelected == true{
            alert =  "select"
        }
        
        //MARK: - Time
        guard let selectedTime = self.selectedTime else {
            print("Select a time")
            return}
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let formattedTime = formatter.string(from: selectedTime)
        var time = ""
        if recurringSelected == true{
            time = "R/PT\(formattedTime)"
        } else {
            time = "PT\(formattedTime)"
        }
        //MARK: - Create Struct
        let body = HueModel.Body(scene: nil,
                                 status: nil,
                                 alert: alert,
                                 bri: self.briValue,
                                 on: self.isOn,
                                 xy: xy)
        let command = HueModel.Command(address: address,
                                       body: body,
                                       method: "PUT")
        let newSchedule = CreateSchedule(name: name,
                                         description: desc,
                                         command: command,
                                         localtime: time)
        //MARK: - Encode and send to bridge
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .withoutEscapingSlashes
            let newScheduleData = try encoder.encode(newSchedule)

            let scheduleString = String(data: newScheduleData, encoding: .utf8) ?? ""
            print(scheduleString)
            
            DataManager.createNewSchedule(baseURL: baseURL,
                                          scheduleData: newScheduleData) { results in
                self.alertClosure(results, "Successfully created schedule: \(name)")
 
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
        let httpBody = ["xy": colorXY]
        DataManager.updateLight(baseURL: baseURL,
                                lightID: lightID,
                                method: .put,
                                httpBody: httpBody,
                                completionHandler: noAlertOnSuccessClosure)
    }
}
