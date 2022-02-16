//
//  EditScheduleView.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 1/6/21.
//

import UIKit

enum ScheduleChoices: String{
    case timer = "Timer"
    case selectTime = "Select a time"
}
enum Time: String{
    case timer = "PT"
    case recurring = "R/PT"
    case recurringTime = "W"
}
protocol ScheduleDelegate: AnyObject{
    func selectGroupTapped()
    func selectLightTapped()
    func timeSelected(time: Date, scheduleType: ScheduleChoices?, scheduleRawValue: Int?)
    func saveTapped(name: String, desc: String)
    func deleteTapped(name: String)
    func flashSelected(flash: scheduleConstants?)
    func recurringToggled(isOn: Bool)
    func onToggle(sender: UISwitch)
    func changeColor(sender: UIButton)
    func briChanged(sender: UISlider)
    func autoDeleteToggled(autoDelete: Bool)
}
class EditScheduleView: UIView{
    
    weak var scheduleDelegate : ScheduleDelegate?
    fileprivate lazy var mainVScroll: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        //        scroll.backgroundColor = .green
        return scroll
    }()
    fileprivate lazy var mainVStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = UI.verticalSpacing
        stack.alignment = .center
        //        stack.backgroundColor = .blue
        return stack
    }()
    
    //MARK: - Schedule Name
    fileprivate var nameHStack : UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillProportionally
        
        stack.spacing = UI.horizontalSpacing
        //        stack.alignment = .trailing
        return stack
    }()
    fileprivate var lblName: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.text = "Name: "
        return label
    }()
    lazy var tfName : UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.text = schedule?.name
        textField.backgroundColor = .white
        textField.placeholder = "Schedule Name"
        textField.textAlignment = .center
        textField.textColor = .black
        return textField
    }()
    //MARK: - Description
    fileprivate var descriptionHStack : UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .equalCentering
        
        stack.spacing = UI.horizontalSpacing
        stack.alignment = .center
        return stack
    }()
    fileprivate var lblDescription: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.text = "Description: "
        return label
    }()
    lazy var tfDescription : UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.text = schedule?.description
        textField.backgroundColor = .white
        textField.textAlignment = .center
        textField.textColor = .black
        return textField
    }()
    //MARK: - Schedule Choices
    fileprivate var scheduleOptions = [
        ScheduleChoices.timer.rawValue,
        ScheduleChoices.selectTime.rawValue
        ]
    fileprivate var scheduleType: ScheduleChoices?{
        didSet{
            if scheduleType == .timer{
                datePicker.datePickerMode = .countDownTimer
                scheduleContainer.isHidden = true
            }
            if scheduleType == .selectTime{
                scheduleContainer.isHidden = false
                datePicker.datePickerMode = .time
                datePicker.preferredDatePickerStyle = .wheels
            }
        }
    }
    fileprivate lazy var scheduleSelection: UISegmentedControl = {
       let sc = UISegmentedControl(items: scheduleOptions)
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.addTarget(self, action: #selector(scheduleTypeSelected), for: .valueChanged)
        if let time = schedule?.localtime{
            if time.contains(Time.timer.rawValue){ // timer previously selected
                sc.selectedSegmentIndex = 0
                self.scheduleType = .timer
            } else { // time previously selected
                sc.selectedSegmentIndex = 1
                self.scheduleType = .selectTime
            }
        } else { // if schedule is nil, default to timer
            sc.selectedSegmentIndex = 0
            self.scheduleType = .timer
        }
        return sc
    }()
    
    //MARK: - Date Picker
    fileprivate lazy var datePicker : UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        if self.scheduleType == .timer{
            datePicker.datePickerMode = .countDownTimer
            datePicker.addTarget(self, action: #selector(timerChanged), for: .valueChanged)
            if let time = schedule?.localtime{
                    print("Schedule time: \(time)")
                    let justTime = time.suffix(8)
                    print(justTime)
                    let hours = justTime.prefix(2)
                    let minutesAndSeconds = justTime.suffix(5)
                    let minutes = minutesAndSeconds.prefix(2)
                    
                    print("hours: \(hours) minutes: \(minutes)")
                    print("Timer before add: \(datePicker.date)")
                    if let dHours = Double(hours),
                       let dMinutes = Double(minutes){
                        datePicker.date +=  ((dHours * 3600) + (dMinutes * 60))
                    } else {
                        datePicker.date += 60
                    }
                    print("Timer after add: \(datePicker.date)")
            } else {
                datePicker.date += 60 // This way it is not 0 which is invalid for the schedule, it will default to 1 which will match the GUI
            }
            print("Timer: \(datePicker.date)")
        }
        if self.scheduleType == .selectTime{
            datePicker.datePickerMode = .time
            datePicker.preferredDatePickerStyle = .wheels
            if let time = schedule?.localtime{
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
//                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                formatter.dateFormat = "HH:mm:ss"
                let justTime = String(time.suffix(8))
                if let formattedDate = formatter.date(from: justTime){
                    datePicker.date = formattedDate
                }
            }
        }
        return datePicker
    }()
    //MARK: - Schedule Container
    fileprivate var scheduleContainer : UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    //MARK: - Schedule Picker
    fileprivate lazy var schedulePicker : SchedulePicker = {
        let schedulePicker = SchedulePicker()
        schedulePicker.translatesAutoresizingMaskIntoConstraints = false
        schedulePicker.delegate = self
        
        if let time = schedule?.localtime{
            if time.contains(Time.recurringTime.rawValue){
                print("Get the bitmask for the days of the week")
                let firstFour = time.prefix(4)
                let bitMask = firstFour.suffix(3)
                print("bitMask: \(bitMask)")
                if let rawValue = Int(bitMask){
                    schedulePicker.schedule = Schedule(rawValue: rawValue)
                }
            }
        } else {
            schedulePicker.schedule = Schedule(rawValue: 0) // none selected
        }
        return schedulePicker
    }()
    //MARK: - Selection H Stack
    fileprivate var selectionHStack : UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = UI.horizontalSpacing
        stack.alignment = .center
        return stack
    }()
    private var btnGroups: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Select a Group", for: .normal)
        button.backgroundColor = .systemBlue
        button.addTarget(self, action: #selector(selectGroup), for: .touchUpInside)
        button.setTitleColor(.label, for: .normal)
        return button
    }()
    private var btnLights: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Select a light", for: .normal)
        button.backgroundColor = .systemGreen
        button.addTarget(self, action: #selector(selectLights), for: .touchUpInside)
        button.setTitleColor(.label, for: .normal)
        return button
    }()
    

    
    fileprivate var lblDoWhat: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.text = "When timer is done, do what:"
        return label
    }()
    
    fileprivate var tableView : UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.register(HueLightsCell.self, forCellReuseIdentifier: Cells.cell)
        tableView.rowHeight = 80
        tableView.backgroundColor = .white
        return tableView
    }()
    //MARK: - Alert Choices
    enum AlertChoices: String{
        case none = "None"
        case flash = "Flash Once"
        case longFlash = "Flash for 15 sec"
    }
    //MARK: - AlertOptions
    fileprivate var alertOptions = [
        AlertChoices.none.rawValue,
        AlertChoices.flash.rawValue,
        AlertChoices.longFlash.rawValue
    ]
    fileprivate var flashSelected : scheduleConstants?
    //MARK: - Segmented Control - Alerts
    fileprivate lazy var scAlerts : UISegmentedControl = {
        let sc = UISegmentedControl(items: alertOptions)
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.addTarget(self, action: #selector(alertSelection), for: .valueChanged)
        if let alert = schedule?.command.body.alert{
            if alert == scheduleConstants.flash.rawValue{
                sc.selectedSegmentIndex = 1
                self.flashSelected = .flash
            }
            if alert == scheduleConstants.longFlash.rawValue{
                sc.selectedSegmentIndex = 2
                self.flashSelected = .longFlash
            }
        } else {
            sc.selectedSegmentIndex = 0
            self.flashSelected = nil
        }
        return sc
    }()

    //MARK: - Recurring H Stack
    fileprivate var recurringHStack : UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = UI.horizontalSpacing
        stack.alignment = .center
        return stack
    }()
    fileprivate var lblRecurring: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Recurring"
        return label
    }()
    fileprivate lazy var swRecurring: UISwitch = {
        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addTarget(self, action: #selector(recurringToggle), for: .valueChanged)
        if let safeTime = schedule?.localtime{
            if safeTime.contains("R"){
                toggle.isOn = true
            }
        }else {
            toggle.isOn = false
        }
        self.autoDeleteHidden = toggle.isOn
        return toggle
    }()
    //MARK: - Auto Delete H Stack
    fileprivate var autoDeleteHidden = Bool(){
        didSet{
            //If recurring is selected, the auto delete command needs to be nil, so user can not select on or off, so hide the h stack
            if autoDeleteHidden == true{
                autoDeleteHStack.isHidden = true
            } else {
                autoDeleteHStack.isHidden = false
            }
        }
    }
    fileprivate var autoDeleteHStack : UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = UI.horizontalSpacing
        stack.alignment = .center
        return stack
    }()
    fileprivate var lblAutoDelete: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Auto Delete?"
        return label
    }()
    fileprivate lazy var swDelete: UISwitch = {
        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addTarget(self, action: #selector(autoDeleteToggled), for: .valueChanged)
        if let safeAutoDelete = schedule?.autodelete{
            toggle.isOn = safeAutoDelete
        }else {
            toggle.isOn = true
        }
        return toggle
    }()
    
    
    private var btnSave : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: .normal)
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .systemGreen
        return button
    }()
    
    
    private var btnDelete : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Delete", for: .normal)
        button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .systemRed
        return button
    }()
     
    
    fileprivate var selectionArray : [Any]?
    fileprivate var groupSelected = false
    fileprivate var schedule: HueModel.Schedules?
    fileprivate var scheduleRawValue: Int? {
        didSet{
            if scheduleRawValue == nil{
                self.recurringHStack.isHidden = false
                self.autoDeleteHStack.isHidden = false // auto delete needs to be nil if recurring is enabled
            } else {
                self.recurringHStack.isHidden = true // recurring has to be enabled for this to work
                self.autoDeleteHStack.isHidden = true // auto delete needs to be nil if recurring is enabled
            }
        }
    }
    init(schedule: HueModel.Schedules?) {
        self.schedule = schedule
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(){
        self.backgroundColor = UI.backgroundColor
        tableView.dataSource = self
        tableView.delegate = self
        self.addSubview(mainVScroll)
        mainVScroll.addSubview(mainVStack)
        // Add Name
        mainVStack.addArrangedSubview(nameHStack)
        nameHStack.addArrangedSubview(lblName)
        nameHStack.addArrangedSubview(tfName)
        
        //Add Description
        mainVStack.addArrangedSubview(descriptionHStack)
        descriptionHStack.addArrangedSubview(lblDescription)
        descriptionHStack.addArrangedSubview(tfDescription)
        
        
        mainVStack.addArrangedSubview(scheduleSelection)
        
        mainVStack.addArrangedSubview(datePicker)
        
        mainVStack.addArrangedSubview(scheduleContainer)
        scheduleContainer.addSubview(schedulePicker)
        
        mainVStack.addArrangedSubview(lblDoWhat)
        
        //Add selection
        mainVStack.addArrangedSubview(selectionHStack)
        selectionHStack.addArrangedSubview(btnGroups)
        selectionHStack.addArrangedSubview(btnLights)
        
        //MARK: - Add TableView
        mainVStack.addArrangedSubview(tableView)
        
        //MARK: - Alerts
        mainVStack.addArrangedSubview(scAlerts)
        
        //MARK: - Recurring H Stack
        mainVStack.addArrangedSubview(recurringHStack)
        recurringHStack.addArrangedSubview(lblRecurring)
        recurringHStack.addArrangedSubview(swRecurring)
        
        //MARK: - Add Auto Delete H Stack
        mainVStack.addArrangedSubview(autoDeleteHStack)
        autoDeleteHStack.addArrangedSubview(lblAutoDelete)
        autoDeleteHStack.addArrangedSubview(swDelete)
        //        self.addSubview(tableView)
        self.addSubview(btnSave)
        
        self.addSubview(btnDelete)
        setupConstraints()
    }
    
    func setupConstraints(){
        let safeArea = self.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            mainVScroll.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: UI.verticalSpacing),
            mainVScroll.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: UI.horizontalSpacing),
            mainVScroll.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -UI.horizontalSpacing),
            mainVScroll.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -50),
            
            mainVStack.topAnchor.constraint(equalTo: mainVScroll.topAnchor),
            mainVStack.widthAnchor.constraint(equalTo: mainVScroll.widthAnchor),
            mainVStack.bottomAnchor.constraint(equalTo: mainVScroll.bottomAnchor),
            
            nameHStack.widthAnchor.constraint(equalTo: mainVStack.widthAnchor),
            tfName.heightAnchor.constraint(equalToConstant: 35),
            tfName.widthAnchor.constraint(equalToConstant: 200),
            
            descriptionHStack.widthAnchor.constraint(equalTo: mainVStack.widthAnchor),
            tfDescription.heightAnchor.constraint(equalToConstant: 35),
            tfDescription.widthAnchor.constraint(equalToConstant: 200),
            
            scheduleContainer.heightAnchor.constraint(equalTo: schedulePicker.heightAnchor),
            scheduleContainer.widthAnchor.constraint(equalTo: mainVStack.widthAnchor),
            schedulePicker.widthAnchor.constraint(equalTo: mainVStack.widthAnchor),
            schedulePicker.heightAnchor.constraint(equalToConstant: 50),
            schedulePicker.centerXAnchor.constraint(equalTo: mainVStack.centerXAnchor),
            
            btnGroups.heightAnchor.constraint(equalToConstant: 44),
            btnGroups.widthAnchor.constraint(equalToConstant: 150),
            
            btnLights.heightAnchor.constraint(equalToConstant: 44),
            btnLights.widthAnchor.constraint(equalToConstant: 150),
            
            
            tableView.heightAnchor.constraint(equalToConstant: 80),
            tableView.widthAnchor.constraint(equalTo: mainVStack.widthAnchor),
            
            btnSave.heightAnchor.constraint(equalToConstant: 40),
            btnSave.widthAnchor.constraint(equalToConstant: 100),
            btnSave.trailingAnchor.constraint(equalTo: safeArea.centerXAnchor, constant: -UI.horizontalSpacing),
            btnSave.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -UI.verticalSpacing),
            
            btnDelete.heightAnchor.constraint(equalToConstant: 40),
            btnDelete.widthAnchor.constraint(equalToConstant: 100),
            btnDelete.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -UI.verticalSpacing),
            btnDelete.leadingAnchor.constraint(equalTo: safeArea.centerXAnchor, constant: UI.horizontalSpacing),
            
        ])
    }
    func updateGroupSelected(groupSelected: Bool){
        self.groupSelected = groupSelected
    }
    
    //MARK: - Obj c functions
    @objc func timerChanged(sender: UIDatePicker){
        print("Selected time: \(sender.date)")
        scheduleDelegate?.timeSelected(time: sender.date, scheduleType: self.scheduleType, scheduleRawValue: self.scheduleRawValue)
        
    }
    @objc func selectGroup(){
        print("select group tapped")
        self.groupSelected = true
        scheduleDelegate?.selectGroupTapped()
    }
    @objc func selectLights(){
        print("Select lights tapped")
        self.groupSelected = false
        scheduleDelegate?.selectLightTapped()
    }
    @objc func saveTapped(){
        print("Save tapped")
        scheduleDelegate?.flashSelected(flash: self.flashSelected)
        scheduleDelegate?.timeSelected(time: datePicker.date, scheduleType: self.scheduleType, scheduleRawValue: self.scheduleRawValue)
        scheduleDelegate?.recurringToggled(isOn: swRecurring.isOn)
        scheduleDelegate?.saveTapped(name: tfName.text!, desc: tfDescription.text!)
    }
    @objc func recurringToggle(sender: UISwitch){
        print("recurring Toggled on: \(sender.isOn)")
        self.autoDeleteHidden = sender.isOn
        scheduleDelegate?.recurringToggled(isOn: sender.isOn)
    }
    @objc func deleteTapped(){
        print("Delete Tapped")
        scheduleDelegate?.deleteTapped(name: tfName.text!)
    }
    @objc func autoDeleteToggled(sender: UISwitch){
        scheduleDelegate?.autoDeleteToggled(autoDelete: sender.isOn)
    }
    @objc func alertSelection(sender: UISegmentedControl){
        let selected = alertOptions[sender.selectedSegmentIndex]
        switch selected{
        case AlertChoices.none.rawValue: print("No alert selected")
            self.flashSelected = nil
        case AlertChoices.flash.rawValue: print("flash once selected")
            self.flashSelected = .flash
        case AlertChoices.longFlash.rawValue: print("long flash selected")
            self.flashSelected = .longFlash
        default: print("Choice not setup in alert selection")
        }
    }
    @objc func scheduleTypeSelected(sender: UISegmentedControl){
        let selected = scheduleOptions[sender.selectedSegmentIndex]
        switch selected{
        case ScheduleChoices.timer.rawValue:
            self.scheduleType = .timer
        case ScheduleChoices.selectTime.rawValue:
            self.scheduleType = .selectTime
        default: print("Choice not setup in schedule selection")
        }
    }
}
//MARK: - TableView DataSource and Delegate
extension EditScheduleView : UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectionArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        if groupSelected == true {
            guard let selectionArray = selectionArray as? [HueModel.Groups] else{return UITableViewCell()}
            let group = selectionArray[indexPath.row]
            cell.lightName = group.name
            if let safeSchedule = self.schedule{
                cell.configureScheduleGroupCell(schedule: safeSchedule, group: group)
            }else {
                cell.configureGroupCell(group: group)
            }
        } else {
            guard let selectionArray = selectionArray as? [HueModel.Light] else{return UITableViewCell()}
            cell.lightName = selectionArray[indexPath.row].name
            let light = selectionArray[indexPath.row]
            if let safeSchedule = self.schedule{
                cell.configureScheduleLightCell(schedule: safeSchedule, light: light)
            }
        }
        cell.backgroundColor = .secondarySystemBackground
        return cell
    }
    func updateSelectionArray(array: [Any]){
        self.selectionArray = array
        
        DispatchQueue.main.async {
            //            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
    
}
//MARK: - Cell Delegate
extension EditScheduleView: HueCellDelegate{
    func onSwitchToggled(sender: UISwitch) {
        print("toggled in view")
        scheduleDelegate?.onToggle(sender: sender)
    }
    
    func brightnessSliderChanged(sender: UISlider) {
        print("Slider changed in view")
        scheduleDelegate?.briChanged(sender: sender)
    }
    
    func changeLightColor(sender: UIButton) {
        print("color change in view")
        scheduleDelegate?.changeColor(sender: sender)
    }
    
    
}
//MARK: - Schedule Picker Delegate
extension EditScheduleView: SchedulePickerDelegate{
    func getScheduleRawValue(rawValue: Int) {
        self.scheduleRawValue = rawValue
    }
    
    
}
