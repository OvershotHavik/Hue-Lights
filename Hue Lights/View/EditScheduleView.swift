//
//  EditScheduleView.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 1/6/21.
//

import UIKit
protocol ScheduleDelegate: class{
    func selectGroupTapped()
    func selectLightTapped()
    func timeSelected(time: Date)
    func saveTapped(name: String, desc: String)
    func deleteTapped(name: String)
    func flashToggled(isOn: Bool)
    func recurringToggled(isOn: Bool)
    func onToggle(sender: UISwitch)
    func changeColor(sender: UIButton)
    func briChanged(sender: UISlider)
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
    fileprivate lazy var tfName : UITextField = {
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
    fileprivate lazy var tfDescription : UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.text = schedule?.description
        textField.backgroundColor = .white
        textField.textAlignment = .center
        textField.textColor = .black
        return textField
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
    
    fileprivate lazy var dpTimer : UIDatePicker = {
        let timer = UIDatePicker()
        timer.translatesAutoresizingMaskIntoConstraints = false
        timer.datePickerMode = .countDownTimer
        timer.addTarget(self, action: #selector(timerChanged), for: .valueChanged)
        if let time = schedule?.localtime{
            print("Schedule time: \(time)")
            let justTime = time.suffix(8)
            print(justTime)
            let hours = justTime.prefix(2)
            let minutesAndSeconds = justTime.suffix(5)
            let minutes = minutesAndSeconds.prefix(2)
            
            print("hours: \(hours) minutes: \(minutes)")
            print("Timer before add: \(timer.date)")
            if let dHours = Double(hours),
               let dMinutes = Double(minutes){
                timer.date +=  ((dHours * 3600) + (dMinutes * 60))
            } else {
                timer.date += 60
            }
            print("Timer after add: \(timer.date)")
        } else {
            timer.date += 60 // This way it is not 0 which is invalid for the schedule, it will default to 1 which will match the gui
        }
        print("Timer: \(timer.date)")
        return timer
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
    //MARK: - Alert H Stack
    fileprivate var alertHStack : UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = UI.horizontalSpacing
        stack.alignment = .center
        return stack
    }()
    fileprivate var lblFlash: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Enable Flash"
        return label
    }()
    fileprivate lazy var swFlash: UISwitch = {
        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        if schedule?.command.body.alert == "select"{
            toggle.isOn = true
        } else {
            toggle.isOn = false
        }
        toggle.addTarget(self, action: #selector(flashToggle), for: .valueChanged)
        return toggle
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
        
        // add timer
        mainVStack.addArrangedSubview(dpTimer)
        
        mainVStack.addArrangedSubview(lblDoWhat)
        
        //Add selection
        mainVStack.addArrangedSubview(selectionHStack)
        selectionHStack.addArrangedSubview(btnGroups)
        selectionHStack.addArrangedSubview(btnLights)
        
        //MARK: - Add TableView
        mainVStack.addArrangedSubview(tableView)
        
        //MARK: - Alert H Stack
        mainVStack.addArrangedSubview(alertHStack)
        alertHStack.addArrangedSubview(lblFlash)
        alertHStack.addArrangedSubview(swFlash)
        
        //MARK: - Recurring H Stack
        mainVStack.addArrangedSubview(recurringHStack)
        recurringHStack.addArrangedSubview(lblRecurring)
        recurringHStack.addArrangedSubview(swRecurring)
        
        
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
            
            btnGroups.heightAnchor.constraint(equalToConstant: 44),
            btnGroups.widthAnchor.constraint(equalToConstant: 150),
            
            btnLights.heightAnchor.constraint(equalToConstant: 44),
            btnLights.widthAnchor.constraint(equalToConstant: 150),
            
            
            //            tableView.topAnchor.constraint(equalTo: safeArea.centerYAnchor, constant: 100),
            tableView.heightAnchor.constraint(equalToConstant: 80),
            tableView.widthAnchor.constraint(equalTo: mainVStack.widthAnchor),
            //            tableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -50),
            
            btnSave.heightAnchor.constraint(equalToConstant: 40),
            btnSave.widthAnchor.constraint(equalToConstant: 100),
//            btnSave.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
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
        scheduleDelegate?.timeSelected(time: sender.date)
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
        scheduleDelegate?.flashToggled(isOn: swFlash.isOn)
        scheduleDelegate?.timeSelected(time: dpTimer.date)
        scheduleDelegate?.recurringToggled(isOn: swRecurring.isOn)
        scheduleDelegate?.saveTapped(name: tfName.text!, desc: tfDescription.text!)
    }
    @objc func flashToggle(sender: UISwitch){
        print("flash toggled on: \(sender.isOn)")
        scheduleDelegate?.flashToggled(isOn: sender.isOn)
    }
    @objc func recurringToggle(sender: UISwitch){
        print("recurring Toggled on: \(sender.isOn)")
        scheduleDelegate?.recurringToggled(isOn: sender.isOn)
    }
    @objc func deleteTapped(){
        print("Delete Tapped")
        scheduleDelegate?.deleteTapped(name: tfName.text!)
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
