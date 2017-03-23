//
//  AddExpenseTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/14/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class AddExpenseTableViewCell: UITableViewCell {

    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var notesButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
