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
            let refresh = refresh ?? (context == nil)
            let context = context ?? getViewContext()
            let objOnContext = (T.inContext(obj.objectID, context: context) as! T)
            if refresh {
                context.refresh(objOnContext, mergeChanges: true)
            }
            return objOnContext
        } else {
            return nil
        }
    }

    /**
     * Returns `objId` in `context`, if it exists, otherwise nil.
     */
    class func inContext(_ objId: NSManagedObjectID?, context: NSManagedObjectContext? = nil) -> NSManagedObject? {
        if let objId = objId {
            let context = context ?? getViewContext()
            return context.object(with: objId)
        } else {
            return nil
        }
    }

    private class func getViewContext() -> NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
}

