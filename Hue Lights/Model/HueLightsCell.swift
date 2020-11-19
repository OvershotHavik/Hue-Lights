//
//  HueLightsCell.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/19/20.
//

import UIKit
struct LightData{
    var lightName: String
    var isOn: Bool
    var brightness: Float
    var isReachable: Bool
}
class HueLightsCell: UITableViewCell {
    var ivImage : UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = .systemGray
        return iv
    }()
    var lblLightName : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .black
        return label
    }()
    var onSwitch : UISwitch = {
        let onSwitch = UISwitch()
        onSwitch.translatesAutoresizingMaskIntoConstraints = false
        onSwitch.isOn = false
        onSwitch.addTarget(self, action: #selector(onSwitchToggle), for: .touchUpInside)
        return onSwitch
    }()
    var brightnessSlider : UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.addTarget(self, action: #selector(brightnessChanged), for: .valueChanged)
        return slider
    }()
    var lightName = String(){
        didSet{
            lblLightName.text = lightName
        }
    }
    var isOn = Bool(){
        didSet{
            onSwitch.isOn = isOn
        }
    }
    var brightness = Float(){
        didSet{
            brightnessSlider.value = brightness
        }
    }
    var isReachable = Bool(){
        didSet{
            if isReachable == false{
                self.lblLightName.alpha = 0.5
                self.onSwitch.alpha = 0.5
                self.brightnessSlider.alpha = 0.5
                onSwitch.isOn = false
            }
        }
    }
//    var lightColor = UIColor()
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        setup()

    }
    
    
    func configureCell(LightData: LightData){
//        lblLightName.text = LightData.lightName
        lightName = LightData.lightName
        isOn = LightData.isOn
        brightness = LightData.brightness
        isReachable = LightData.isReachable
    }
    
    
    func setup(){
        addSubview(ivImage)
        addSubview(lblLightName)
        addSubview(onSwitch)
        addSubview(brightnessSlider)
        
        setupConstraints()
    }
    func setupConstraints(){
        let safeArea = self.safeAreaLayoutGuide
        NSLayoutConstraint.activate([

            ivImage.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: UI.horizontalSpacing),
            ivImage.widthAnchor.constraint(equalToConstant: 45),
            ivImage.heightAnchor.constraint(equalToConstant: 45),
            ivImage.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),


            lblLightName.leadingAnchor.constraint(equalTo: ivImage.trailingAnchor, constant: UI.horizontalSpacing),
            lblLightName.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),


            onSwitch.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -UI.horizontalSpacing),
            onSwitch.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),

            
            brightnessSlider.topAnchor.constraint(equalTo: lblLightName.bottomAnchor),
            brightnessSlider.leadingAnchor.constraint(equalTo: lblLightName.leadingAnchor),
            brightnessSlider.trailingAnchor.constraint(equalTo: onSwitch.leadingAnchor),
            
        ])
    }
    @objc func onSwitchToggle(sender: UISwitch){
        if sender == onSwitch{
            if sender.isOn{
                print("switched on")
            } else {
                print("Switched off")
            }
        }
    }
    @objc func brightnessChanged(sender: UISlider){
        if sender == brightnessSlider{
            print("value changed: \(sender.value)")
        }
        
    }
}
