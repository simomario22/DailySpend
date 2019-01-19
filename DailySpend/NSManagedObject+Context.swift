//
//  NSManagedObject+Context.swift
//  DailySpend
//
//  Created by Josh Sherick on 1/2/19.
//  Copyright © 2019 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {
    /**
     * Returns `obj` in `context`, if it exists, otherwise nil.
     *
     * If context is not specified, the app delegate's view context will be
     * used.
     *
     * Optionally, refreshes the object with `mergeChanges: true` on the passed
     * context.
     *
     * The default value for `refresh` is false if a context is passed, and
     * `true` if a context is not passed (and the view context is used).
     */
    class func inContext<T:NSManagedObject>(_ obj: T?, context: NSManagedObjectContext? = nil, refresh: Bool? = nil) -> T? {
        if let obj = obj {
            let objectOnContext = (T.inContext(obj.objectID, context: context, refresh: refresh) as! T)
            return objectOnContext
        } else {
            return nil
        }
    }

    /**
     * Returns `objId` in `context`, if it exists, otherwise nil.
     */
    class func inContext<T:NSManagedObject>(_ objId: NSManagedObjectID?, context: NSManagedObjectContext? = nil, refresh: Bool? = nil) -> T? {
        if let objId = objId {
            let contextToUse = context ?? getViewContext()
            let objectOnContext = contextToUse.object(with: objId) as! T
            if context == nil || refresh == true {
                contextToUse.refresh(objectOnContext, mergeChanges: true)
            }
            return objectOnContext
        } else {
            return nil
        }
    }

    private class func getViewContext() -> NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
}

