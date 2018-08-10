//
//  Image+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 1/26/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//
//

import Foundation
import CoreData


extension Image {

    @nonobjc class func fetchRequest() -> NSFetchRequest<Image> {
        return NSFetchRequest<Image>(entityName: "Image")
    }

    @NSManaged var dateCreated_: NSDate?
    @NSManaged var imageName_: String?
    @NSManaged var expense_: Expense?

}
