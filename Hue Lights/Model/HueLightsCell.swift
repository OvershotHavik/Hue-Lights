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

class HueLightsCell: UITableViewCell {
    var cellDelegate: HueCellDelegate?
    
    lazy var btnChangeColor : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
//        button.setTitle("Color", for: .normal)
        button.setImage(UIImage(systemName: "eyedropper"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(changeColorTapped), for: .touchUpInside)
        return button
    }()
    var lblLightName : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
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
            if isOn == true{
                brightnessSlider.isHidden = false
                btnChangeColor.isHidden = false
            } else {
                brightnessSlider.isHidden = true // can't adjust bri if light is off
                btnChangeColor.isHidden = true // can't adjust the color if light is off
            }
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
                self.btnChangeColor.isHidden = true
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
    //MARK: - Configure Light Cell
    func configureLightCell(light: HueModel.Light){
        lightName = light.name
        isOn = light.state.on
        brightness = Float(light.state.bri)
        if brightness == 0{
            noLightsInGroup = true
        }
        isReachable = light.state.reachable
        if light.state.xy != nil{
            btnChangeColor.backgroundColor = ConvertColor.getRGB(xy: light.state.xy, bri: light.state.bri)
        } else {
            btnChangeColor.setImage(UIImage(), for: .normal)
            btnChangeColor.backgroundColor = ConvertColor.getRGB(xy: UI.readWhiteXY, bri: 254) // default to the readWhite color temp
            btnChangeColor.isEnabled = false
        }
    }
    //MARK: - Configure Group Cell
    func configureGroupCell(group: HueModel.Groups){
        lightName = group.name
        isOn = group.action.on
        
        if let safeBri = group.action.bri{
            brightness = Float(safeBri)
        }
        if brightness == 0{
            noLightsInGroup = true
        }
        isReachable = true
        if group.action.xy != nil{
            btnChangeColor.backgroundColor = ConvertColor.getRGB(xy: group.action.xy, bri: Int(brightness))
        } else {
            btnChangeColor.setImage(UIImage(), for: .normal)
            btnChangeColor.backgroundColor = ConvertColor.getRGB(xy: UI.readWhiteXY, bri: 254) // default to the readWhite color temp
            btnChangeColor.isEnabled = false
        }
    }
    //MARK: - Configure Schedule Group Cell
    func configureScheduleGroupCell(schedule: HueModel.Schedules, group: HueModel.Groups){
        if let safeBri = schedule.command.body.bri{
            self.brightness = Float(safeBri)
        } else {
            if let bri = group.action.bri{
                self.brightness = Float(bri)
            }
        }
        if let safeOn = schedule.command.body.on{
            self.isOn = safeOn
        } else {
            self.isOn = group.action.on
        }
        if let safeXY = schedule.command.body.xy{
            self.btnChangeColor.backgroundColor = ConvertColor.getRGB(xy: safeXY, bri: Int(self.brightness))
        } else {
            if let xy = group.action.xy{
                self.btnChangeColor.backgroundColor = ConvertColor.getRGB(xy: xy, bri: Int(self.brightness))
            } else {
                self.btnChangeColor.setImage(UIImage(), for: .normal)
                self.btnChangeColor.backgroundColor = ConvertColor.getRGB(xy: UI.readWhiteXY, bri: 254) // default to the readWhite color temp
                self.btnChangeColor.isEnabled = false
            }
        }
    }
    
    //MARK: - Configure Schedule Light Cell
    func configureScheduleLightCell(schedule: HueModel.Schedules, light: HueModel.Light){
        if let safeBri = schedule.command.body.bri{
            self.brightness = Float(safeBri)
        } else {
            self.brightness = Float(light.state.bri)
        }
        if let safeOn = schedule.command.body.on{
            self.isOn = safeOn
        } else {
            self.isOn = light.state.on
        }
        if let safeXY = schedule.command.body.xy{
            self.btnChangeColor.backgroundColor = ConvertColor.getRGB(xy: safeXY, bri: Int(self.brightness))
        } else {
            if let xy = light.state.xy{
                self.btnChangeColor.backgroundColor = ConvertColor.getRGB(xy: xy, bri: Int(self.brightness))
            } else {
                self.btnChangeColor.setImage(UIImage(), for: .normal)
                self.btnChangeColor.backgroundColor = ConvertColor.getRGB(xy: UI.readWhiteXY, bri: 254) // default to the readWhite color temp
                self.btnChangeColor.isEnabled = false
            }
        }
    }
    //MARK: - Setup
    func setup(){
        contentView.addSubview(btnChangeColor)
        contentView.addSubview(lblLightName)
        contentView.addSubview(onSwitch)
        contentView.addSubview(brightnessSlider)
        contentView.addSubview(lblBrightness)
        setupConstraints()
    }
    //MARK: - Setup Constraints
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
    //MARK: - Objc Functions
    @objc func onSwitchToggle(sender: UISwitch){
        isOn = sender.isOn
        if isOn == true{
            brightnessSlider.isHidden = false
        } else {
            brightnessSlider.isHidden = true // can't adjust bri if light is off
        }
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
