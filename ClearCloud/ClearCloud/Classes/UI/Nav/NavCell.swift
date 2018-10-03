//
//  NavCell.swift
//  ClearCloud
//
//  Created by Boris Katok on 10/3/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit

class NavCell: UITableViewCell {

    @IBOutlet weak var navimage: UIImageView!
    @IBOutlet weak var navlabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
