//
//  TableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/26/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var textField: UITextField!
    weak var delegate:TableViewCellDelegate?
    var rowPosition:Int?
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("editing!")
        delegate?.didBeginEditingg(sender: self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
        // Initialization code
        print("awakened")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

protocol TableViewCellDelegate: class {
    func didBeginEditingg(sender: TableViewCell)
}
