//
//  HueLightsCell.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/19/20.
//

import UIKit

protocol HueCellDelegate {
    func onSwitchToggled(sender: UISwitch)
    func brightnessSliderChanged(sender: UISlider)
    func changeLightColor(sender: UIButton)
}
struct LightData{
    var lightName: String
    var isOn: Bool
    var brightness: Float
    var isReachable: Bool
    var lightColor: UIColor
}
class HueLightsCell: UITableViewCell {
    var cellDelegate: HueCellDelegate?
    
    lazy var btnChangeColor : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
//        button.setTitle("Color", for: .normal)
        button.setImage(UIImage(systemName: "eyedropper"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(changeColorTapped), for: .touchUpInside)
        return button
    }()
    var lblLightName : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .black
        return label
    }()
    lazy var onSwitch : UISwitch = {
        let onSwitch = UISwitch()
        onSwitch.translatesAutoresizingMaskIntoConstraints = false
        onSwitch.isOn = false
        onSwitch.addTarget(self, action: #selector(onSwitchToggle), for: .valueChanged)
        return onSwitch
    }()
    lazy var brightnessSlider : UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 1
        slider.maximumValue = 254
        slider.addTarget(self, action: #selector(brightnessChanged), for: .valueChanged)
        return slider
    }()
    var lblBrightness: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.numberOfLines = 1
        return label
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
            let sliderValue = (brightnessSlider.value/brightnessSlider.maximumValue) * 100
            lblBrightness.text = String(format: "%.0f", sliderValue) + "%"
        }
    }
    var isReachable = Bool(){
        didSet{
            if isReachable == false{
                self.lblLightName.alpha = 0.5
                self.lblLightName.text! += " - Unreachable"
                self.onSwitch.isHidden = true
                self.brightnessSlider.isHidden = true
                self.lblBrightness.isHidden = true
                onSwitch.isOn = false
            }
        }
    }
    var noLightsInGroup = Bool(){
        didSet{
            if noLightsInGroup == true{
                self.lblLightName.alpha = 0.5
                self.lblLightName.text! += " - No lights in group"
                self.onSwitch.isHidden = true
                self.brightnessSlider.isHidden = true
                self.lblBrightness.isHidden = true
            }
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setup()
    }
    
    
    func configureCell(LightData: LightData){
        lightName = LightData.lightName
        isOn = LightData.isOn
        brightness = LightData.brightness
        if brightness == 0{
            noLightsInGroup = true
        }
        isReachable = LightData.isReachable
        btnChangeColor.backgroundColor = LightData.lightColor
    }
    
    
    func setup(){
        contentView.addSubview(btnChangeColor)
        contentView.addSubview(lblLightName)
        contentView.addSubview(onSwitch)
        contentView.addSubview(brightnessSlider)
        contentView.addSubview(lblBrightness)
        setupConstraints()
    }
    func setupConstraints(){
        let safeArea = contentView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            btnChangeColor.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: UI.horizontalSpacing),
            btnChangeColor.widthAnchor.constraint(equalToConstant: 45),
            btnChangeColor.heightAnchor.constraint(equalToConstant: 45),
            btnChangeColor.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),


            lblLightName.leadingAnchor.constraint(equalTo: btnChangeColor.trailingAnchor, constant: UI.horizontalSpacing),
            lblLightName.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),


            onSwitch.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -UI.horizontalSpacing),
            onSwitch.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),

            
            lblBrightness.bottomAnchor.constraint(equalTo: brightnessSlider.topAnchor),
            lblBrightness.trailingAnchor.constraint(equalTo: brightnessSlider.trailingAnchor),
            
            brightnessSlider.topAnchor.constraint(equalTo: lblLightName.bottomAnchor),
            brightnessSlider.leadingAnchor.constraint(equalTo: lblLightName.leadingAnchor),
            brightnessSlider.trailingAnchor.constraint(equalTo: onSwitch.leadingAnchor, constant: -20),
        ])
        
    }
    @objc func onSwitchToggle(sender: UISwitch){
        cellDelegate?.onSwitchToggled(sender: sender)
    }
    @objc func brightnessChanged(sender: UISlider){
        cellDelegate?.brightnessSliderChanged(sender: sender)
        let sliderValue = (sender.value/sender.maximumValue) * 100
        lblBrightness.text = String(format: "%.0f", sliderValue) + "%"
    }
    @objc func changeColorTapped(sender: UIButton){
        print("change color")
        cellDelegate?.changeLightColor(sender: sender)
        
    }

}
