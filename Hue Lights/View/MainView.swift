//
//  MainView.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/15/20.
//

import UIKit


protocol GetDelegate: class{
    func getTapped(sender: String)
}


class MainView: UIView {
    weak var getDelegate: GetDelegate?
    fileprivate var btnGetLightInfo : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(UI.lights, for: .normal)
        button.addTarget(self, action: #selector(getInfo), for: .touchUpInside)
        return button
    }()
    fileprivate var btnGetGroupInfo : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(UI.groups, for: .normal)
        button.addTarget(self, action: #selector(getInfo), for: .touchUpInside)
        return button
    }()
    fileprivate var btnGetSchedulesInfo : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(UI.schedules, for: .normal)
        button.addTarget(self, action: #selector(getInfo), for: .touchUpInside)
        return button
    }()
    lazy var lblTitle : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Test label"
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(){
        backgroundColor = UI.backgroundColor
        addSubview(btnGetLightInfo)
        addSubview(btnGetGroupInfo)
        addSubview(btnGetSchedulesInfo)
        addSubview(lblTitle)
        setupConstraints()
    }

    func setupConstraints(){
        let safeArea = self.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            btnGetLightInfo.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor, constant: -100),
            btnGetLightInfo.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            
            btnGetGroupInfo.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            btnGetGroupInfo.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            
            btnGetSchedulesInfo.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor, constant: 100),
            btnGetSchedulesInfo.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
        ])
    }
    
    @objc func getInfo(sender: UIButton){
        if let safeTitle = sender.titleLabel?.text{
            getDelegate?.getTapped(sender: safeTitle)
        }
    }
}
