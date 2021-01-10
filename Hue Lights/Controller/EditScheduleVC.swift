//
//  EditScheduleVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 1/6/21.
//

import UIKit

class EditScheduleVC: UIViewController {
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
        print("Name: \(name), desc: \(desc)")
        guard let time = self.selectedTime else {return}
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        print("Hour: \(hour), minute: \(minute)")
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
