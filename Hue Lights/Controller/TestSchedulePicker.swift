//
//  TestSchedulePicker.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 1/15/21.
//

import UIKit

extension UserDefaults {

    enum Keys {

        static let schedule = "schedule"

    }

}
class testSchedulePicker: UIViewController{
    fileprivate var schedulePicker = SchedulePicker()    
    let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    func setupView(){
        view.backgroundColor = .cyan
        
        view.addSubview(schedulePicker)
        schedulePicker.translatesAutoresizingMaskIntoConstraints = false
//        setupSchedulePicker()
        schedulePicker.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        schedulePicker.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        schedulePicker.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        schedulePicker.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        setupSchedulePicker()
    }
    fileprivate func setupSchedulePicker() {
        // Fetch Stored Value
//        let scheduleRawValue = UserDefaults.standard.integer(forKey: UserDefaults.Keys.schedule)
        let scheduleRawValue = 22
        // Configure Schedule Picker
        schedulePicker.schedule = Schedule(rawValue: scheduleRawValue)
    }
}
/*
struct Schedule: OptionSet{
    let rawValue: Int
    
    static let monday       = Schedule(rawValue: 1 << 0) // 1
    static let tuesday      = Schedule(rawValue: 1 << 1) // 2
    static let wednesday    = Schedule(rawValue: 1 << 2) // 4
    static let thursday     = Schedule(rawValue: 1 << 3) // 8
    static let friday       = Schedule(rawValue: 1 << 4) // 16
    static let saturday     = Schedule(rawValue: 1 << 5) // 32
    static let sunday       = Schedule(rawValue: 1 << 6) // 64
    
    static let weekend: Schedule = [.saturday, .sunday]
    static let weekDays : Schedule = [.monday, .tuesday, .wednesday, .thursday, .friday]
}
*/
/*
class SchedulePicker : UIControl {
    var schedule: Schedule = []{
        didSet {updateView()}
    }
    private var buttons: [UIButton] = []
    private enum Color {
        static let selected = UIColor.white
        static let tint = UIColor(red:1.0, green: 0.37, blue:0.36, alpha: 1.0)
        static let normal = UIColor(red:0.2, green:0.25, blue:0.3, alpha:1.0)
    }
    init() {
        super.init(frame: .zero)
        setupButtons()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        setupButtons()
    }
    func updateView(){
        updateButtons()

    }

    private func updateButtons() {
        buttons[0].isSelected = schedule.contains(.monday)
        buttons[1].isSelected = schedule.contains(.tuesday)
        buttons[2].isSelected = schedule.contains(.wednesday)
        buttons[3].isSelected = schedule.contains(.thursday)
        buttons[4].isSelected = schedule.contains(.friday)
        buttons[5].isSelected = schedule.contains(.saturday)
        buttons[6].isSelected = schedule.contains(.sunday)
    }
    func setupButtons() {
        // Create Button
        for title in [ "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" ] {
            // Initialize Button
            let button = UIButton(type: .system)

            // Configure Button
            button.setTitle(title, for: .normal)

            button.tintColor = Color.tint
            button.setTitleColor(Color.normal, for: .normal)
            button.setTitleColor(Color.selected, for: .selected)

            button.addTarget(self, action: #selector(toggleSchedule(_:)), for: .touchUpInside)

            // Add to Buttons
            buttons.append(button)
        }

        // Initialize Stack View
        let stackView = UIStackView(arrangedSubviews: buttons)

        // Add as Subview
        addSubview(stackView)

        // Configure Stack View
        stackView.spacing = 8.0
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Add Constraints
        topAnchor.constraint(equalTo: stackView.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: stackView.bottomAnchor).isActive = true
        leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
    }
    @IBAction func toggleSchedule(_ sender: UIButton) {
        guard let index = buttons.firstIndex(of: sender) else {
            return
        }
        // Helpers
        let element: Schedule.Element

        switch index {
        case 0: element = .monday
        case 1: element = .tuesday
        case 2: element = .wednesday
        case 3: element = .thursday
        case 4: element = .friday
        case 5: element = .saturday
        default: element = .sunday
        }
        // Update Schedule
        if schedule.contains(element) {
            schedule.remove(element)
        } else {
            schedule.insert(element)
        }
        // Update Buttons
        updateButtons()
        // Send Actions
//        sendActions(for: .valueChanged)
        scheduleDidChange(self)
    }
    // MARK: - Actions

    func scheduleDidChange(_ sender: SchedulePicker) {
        // Helpers
//        let userDefaults = UserDefaults.standard

        // Store Value
        let scheduleRawValue = sender.schedule.rawValue
        print("schedule raw value: \(scheduleRawValue)")
//        userDefaults.set(scheduleRawValue, forKey: UserDefaults.Keys.schedule)
//        userDefaults.synchronize()
    }
}
*/
