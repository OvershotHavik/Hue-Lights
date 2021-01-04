//
//  MainView.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/15/20.
//

import UIKit


protocol GetDelegate: class{
    func getTapped(sender: HueSender)
}
protocol BridgeDelegate: class{
    func selectedBridge(bridge: Discovery)
}

class MainView: UIView {
    weak var getDelegate: GetDelegate?
    weak var bridgeDelegate: BridgeDelegate?
    fileprivate var discoveredBridges : [Discovery]?
    fileprivate var tableView : UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ListCell.self, forCellReuseIdentifier: Cells.cell)
        tableView.rowHeight = 50
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    fileprivate var btnGetLightInfo : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(HueSender.lights.rawValue, for: .normal)
        button.addTarget(self, action: #selector(getInfo), for: .touchUpInside)
        return button
    }()
    fileprivate var btnGetGroupInfo : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(HueSender.groups.rawValue, for: .normal)
        button.addTarget(self, action: #selector(getInfo), for: .touchUpInside)
        return button
    }()
    fileprivate var btnGetSchedulesInfo : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(HueSender.schedules.rawValue, for: .normal)
        button.addTarget(self, action: #selector(getInfo), for: .touchUpInside)
        return button
    }()
    fileprivate var btnLightScenes : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(HueSender.lightScenes.rawValue, for: .normal)
        button.addTarget(self, action: #selector(getInfo), for: .touchUpInside)
        return button
    }()
    lazy var lblTitle : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Test label"
        return label
    }()

    fileprivate var selectedBridgeID: String?
    init(selectedBridgeID: String?, frame: CGRect = .zero) {
        self.selectedBridgeID = selectedBridgeID
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(){
        tableView.delegate = self
        tableView.dataSource = self
        backgroundColor = UI.backgroundColor
        addSubview(tableView)
        addSubview(btnGetLightInfo)
        addSubview(btnGetGroupInfo)
        addSubview(btnGetSchedulesInfo)
        addSubview(btnLightScenes)
        setupConstraints()
    }

    func setupConstraints(){
        let safeArea = self.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: UI.verticalSpacing),
            tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: UI.horizontalSpacing),
            tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -UI.horizontalSpacing),
            tableView.heightAnchor.constraint(equalToConstant: 100),
            
            
            btnGetLightInfo.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor, constant: -100),
            btnGetLightInfo.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            
            btnGetGroupInfo.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            btnGetGroupInfo.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            
            btnGetSchedulesInfo.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor, constant: 100),
            btnGetSchedulesInfo.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            
            btnLightScenes.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor, constant: 200),
            btnLightScenes.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
        ])
    }
    
    @objc func getInfo(sender: UIButton){
        if let safeTitle = sender.titleLabel?.text{
            getDelegate?.getTapped(sender: HueSender(rawValue: safeTitle)!)
        }
    }
    func updateTable(list: [Discovery], selectedBridge: String){
        self.selectedBridgeID = selectedBridge
        self.discoveredBridges = list
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
}
//MARK: - TableView Delegates
extension MainView: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredBridges?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! ListCell
        guard let discoveredBridges = discoveredBridges else {return cell}
        let bridge = discoveredBridges[indexPath.row]
        if bridge.id == selectedBridgeID{
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        cell.lblListItem.text = "Hue Bridge IP: \(bridge.internalipaddress)"
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let discoveredBridges = discoveredBridges else {return}
        let bridge = discoveredBridges[indexPath.row]
        // Unselect the row.
        tableView.deselectRow(at: indexPath, animated: false)
        bridgeDelegate?.selectedBridge(bridge: bridge)
    }
    
}
