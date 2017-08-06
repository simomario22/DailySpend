//
//  Image+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 6/29/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData


extension Image {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Image> {
        return NSFetchRequest<Image>(entityName: "Image")
    }

    @NSManaged public var imageName_: String?
    @NSManaged public var dateCreated_: NSDate?
    @NSManaged public var expense_: Expense?

}
