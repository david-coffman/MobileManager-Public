//
//  VoterTableViewCell.swift
//  Digital Campaign Manager
//
//  Created by David Coffman on 7/8/19.
//  Copyright © 2019 David Coffman. All rights reserved.
//

import UIKit

class VoterTableViewCell: UITableViewCell {

    @IBOutlet var partyLabelImage: UIImageView!
    @IBOutlet var raceLabelImage: UIImageView!
    @IBOutlet var genderLabelImage: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var engagementIndicator: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
