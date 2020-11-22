//
//  MainView.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/15/20.
//

import UIKit


protocol GetDelegate: class{
    func getTapped()
}


class MainView: UIView {
    weak var getDelegate: GetDelegate?
    fileprivate var btnGetItems : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Get info", for: .normal)
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
        backgroundColor = .systemBlue
        addSubview(btnGetItems)
        addSubview(lblTitle)
        setupConstraints()
    }

    func setupConstraints(){
        let safeArea = self.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            btnGetItems.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            btnGetItems.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
        ])
    }
    
    @objc func getInfo(){
        getDelegate?.getTapped()
    }
}
