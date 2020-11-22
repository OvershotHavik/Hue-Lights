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
}
struct LightData{
    var lightName: String
    var isOn: Bool
    var brightness: Float
    var isReachable: Bool
}
class HueLightsCell: UITableViewCell {
    var cellDelegate: HueCellDelegate?
    
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
        slider.maximumValue = 255
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
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setup()

    }
    
    
    func configureCell(LightData: LightData){
        lightName = LightData.lightName
        isOn = LightData.isOn
        brightness = LightData.brightness
        isReachable = LightData.isReachable
    }
    
    
    func setup(){
        contentView.addSubview(ivImage)
        contentView.addSubview(lblLightName)
        contentView.addSubview(onSwitch)
        contentView.addSubview(brightnessSlider)
        contentView.addSubview(lblBrightness)
        setupConstraints()
    }
    func setupConstraints(){
        let safeArea = contentView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            ivImage.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: UI.horizontalSpacing),
            ivImage.widthAnchor.constraint(equalToConstant: 45),
            ivImage.heightAnchor.constraint(equalToConstant: 45),
            ivImage.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),


            lblLightName.leadingAnchor.constraint(equalTo: ivImage.trailingAnchor, constant: UI.horizontalSpacing),
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
    

}
