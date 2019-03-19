//
//  TableViewInputCell.swift
//  UnidirectionDataFlow
//
//  Created by 师飞 on 2019/3/19.
//  Copyright © 2019年 师飞. All rights reserved.
//

import UIKit

protocol TableViewInputCellDelegate: class {
    func inputChanged(cell: TableViewInputCell, text: String)
}

class TableViewInputCell: UITableViewCell {
    
    @IBOutlet weak var textFiled: UITextField!
    weak var delegate: TableViewInputCellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    @objc @IBAction func textFiledValueChanged(_ sender: UITextField) {
        self.delegate?.inputChanged(cell: self, text: textFiled.text ?? "")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
