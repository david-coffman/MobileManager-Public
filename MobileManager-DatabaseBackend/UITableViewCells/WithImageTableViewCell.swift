//
//  WithImageTableViewCell.swift
//  Digital Campaign Manager
//
//  Created by David Coffman on 7/9/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import UIKit

class WithImageTableViewCell: UITableViewCell {

    @IBOutlet var sideImage: UIImageView!
    @IBOutlet var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
