//
//  ListCell.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/28/20.
//
import UIKit

struct ListData {
    var title: String
    var image: UIImage
}

class ListCell: UITableViewCell{
    var lblListItem = UILabel()
    var ivImage = GetImageFromURLIV()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .none
        configureLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureLabel(){
        addSubview(ivImage)
        ivImage.translatesAutoresizingMaskIntoConstraints = false
        ivImage.layer.cornerRadius = 10
        ivImage.clipsToBounds = true
        
        addSubview(lblListItem)
        lblListItem.translatesAutoresizingMaskIntoConstraints = false
        lblListItem.numberOfLines = 0
        lblListItem.adjustsFontSizeToFitWidth = true
        lblListItem.textColor = .label
        
        NSLayoutConstraint.activate([
            ivImage.centerYAnchor.constraint(equalTo: centerYAnchor),
            ivImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            ivImage.heightAnchor.constraint(equalToConstant: 45),
            ivImage.widthAnchor.constraint(equalToConstant: 45),
            
            lblListItem.centerYAnchor.constraint(equalTo: centerYAnchor),
            lblListItem.leadingAnchor.constraint(equalTo: ivImage.trailingAnchor, constant: 15),
            lblListItem.heightAnchor.constraint(equalToConstant: 50),
            lblListItem.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
        ])
    }
}

