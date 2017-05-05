//
//  Export.swift
//  DailySpend
//
//  Created by Josh Sherick on 4/14/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

let encoding = String.Encoding.utf8

func desc(_ obj: Any) -> String {
    return String(describing: obj)
}

class Exporter {
    // Escapes and encodes an item.
    class func encodeItem(_ item: String) -> Data? {
        var escapedString = ""
        let doubleQuoteCharacter = Character("\"")
        
        let twoDoubleQuotes = "\"\""
        
        for c in item.characters {
            if c == doubleQuoteCharacter {
                escapedString.append(twoDoubleQuotes)
            } else {
                escapedString.append(c)
            }
        }
        
        let doubleQuoteData = "\"".data(using: encoding)!
        let stringData = escapedString.data(using: encoding)
        
        if stringData == nil {
            return nil
        }
        
        return doubleQuoteData + stringData! + doubleQuoteData
    }
    
    // Escapes and encodes multiple items onto one row and returns the row.
    class func encodeItems(_ items: String...) -> Data? {
        var itemData = Data()
        
        let commaData = ",".data(using: encoding)!
        for (i, item) in items.enumerated() {
            if let data = encodeItem(item) {
                itemData.append(data)
                if i != items.count - 1 {
                    itemData.append(data)
                }
            } else {
                return nil
            }
            itemData.append(commaData)
        }
        
        let crlfData = "\r\n".data(using: encoding)!
        return itemData + crlfData
        
    }

    class func export() -> URL? {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let cacheDirectory = paths[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yy-HHmmss"
        let name = dateFormatter.string(from: Date())
        let filePath = cacheDirectory + "/\(name).dailyspend"
        
        let fm = FileManager.default
        fm.createFile(atPath: filePath, contents: Data(), attributes: nil)
        
        if let os = FileHandle(forWritingAtPath: filePath) {
            let formatDescription = [
                "# This is a text format with multiple tables of comma separated values.\r\n",
                "# \r\n",
                "# There are five tables: Months, MonthAdjustments, Days, DayAdjustments, and\r\n",
                "# Expenses. These tables are labeled on their own line without quotes.\r\n",
                "# \r\n",
                "# Data for each of these tables follows, first with a header row, then record\r\n",
                "# data following in double quotes. Data is encoded in UTF-8, and double quotes\r\n",
                "# are escaped with a preceeding double quote (e.g. \" -> \"\").\r\n",
                "# Header rows are for explanation purposes only and cannot be changed.\r\n",
                "# Lines starting with \"# \" are comments and are ignored.\r\n"
            ]
            
            for line in formatDescription {
                os.write(line.data(using: encoding)!)
            }
            
            // Write month headers
            os.write("Months\r\n".data(using: encoding)!)
            if let monthHeaders = encodeItems("dailyBaseTargetSpend", "month", "dateCreated") {
                os.write(monthHeaders)
            } else {
                os.closeFile()
                return nil
            }
            
            // Fetch all months
            let monthsFetchReq: NSFetchRequest<Month> = Month.fetchRequest()
            let monthSortDesc = NSSortDescriptor(key: "month_", ascending: true)
            monthsFetchReq.sortDescriptors = [monthSortDesc]
            if let months = try? context.fetch(monthsFetchReq) {
                for month in months {
                    let dbtsStr = desc(month.dailyBaseTargetSpend!)
                    let monthStr = desc(month.month!.timeIntervalSince1970)
                    let createdStr = desc(month.dateCreated!.timeIntervalSince1970)
                    
                    if let monthData = encodeItems(dbtsStr, monthStr, createdStr) {
                        os.write(monthData)
                    } else {
                        os.closeFile()
                        return nil
                    }
                }
            } else {
                os.closeFile()
                return nil
            }
            
            // Write monthAdj headers
            os.write("MonthAdjustments\r\n".data(using: encoding)!)
            if let monthAdjHeaders = encodeItems("amount", "reason", "dateEffective", "month", "dateCreated") {
                os.write(monthAdjHeaders)
            } else {
                os.closeFile()
                return nil
            }
            
            let monthAdjReq: NSFetchRequest<MonthAdjustment> = MonthAdjustment.fetchRequest()
            let monthAdjSortDesc = NSSortDescriptor(key: "dateCreated_", ascending: true)
            monthAdjReq.sortDescriptors = [monthAdjSortDesc]
            if let monthAdjs = try? context.fetch(monthAdjReq) {
                for monthAdj in monthAdjs {
                    let amountStr = desc(monthAdj.amount!)
                    let reasonStr = desc(monthAdj.reason!)
                    let effectiveStr = desc(monthAdj.dateEffective!.timeIntervalSince1970)
                    let monthStr = desc(monthAdj.month!.month!.timeIntervalSince1970)
                    let createdStr = desc(monthAdj.dateCreated!.timeIntervalSince1970)
                    
                    if let monthAdjData = encodeItems(amountStr,
                                                 reasonStr,
                                                 effectiveStr,
                                                 monthStr,
                                                 createdStr) {
                        os.write(monthAdjData)
                    } else {
                        os.closeFile()
                        return nil
                    }
                }
            } else {
                os.closeFile()
                return nil
            }
            
            
            // Write day headers
            os.write("Days\r\n".data(using: encoding)!)
            if let dayHeaders = encodeItems("baseTargetSpend", "date", "dateCreated") {
                os.write(dayHeaders)
            } else {
                os.closeFile()
                return nil
            }
            
            let dayFetchReq: NSFetchRequest<Day> = Day.fetchRequest()
            let daySortDesc = NSSortDescriptor(key: "date_", ascending: true)
            dayFetchReq.sortDescriptors = [daySortDesc]
            if let days = try? context.fetch(dayFetchReq) {
                for day in days {
                    let btsStr = desc(day.baseTargetSpend!)
                    let dateStr = desc(day.date!.timeIntervalSince1970)
                    let createdStr = desc(day.dateCreated!.timeIntervalSince1970)
                    
                    if let dayData = encodeItems(btsStr, dateStr, createdStr) {
                        os.write(dayData)
                    } else {
                        os.closeFile()
                        return nil
                    }
                }
            } else {
                os.closeFile()
                return nil
            }
            
            
            // Write dayAdj headers
            os.write("DayAdjustments\r\n".data(using: encoding)!)
            if let dayAdjHeaders = encodeItems("amount", "reason", "dateAffected", "day", "dateCreated") {
                os.write(dayAdjHeaders)
            } else {
                os.closeFile()
                return nil
            }
            
            let dayAdjReq: NSFetchRequest<DayAdjustment> = DayAdjustment.fetchRequest()
            let dayAdjSortDesc = NSSortDescriptor(key: "dateCreated_", ascending: true)
            dayAdjReq.sortDescriptors = [dayAdjSortDesc]
            if let dayAdjs = try? context.fetch(dayAdjReq) {
                for dayAdj in dayAdjs {
                    let amountStr = desc(dayAdj.amount!)
                    let reasonStr = desc(dayAdj.reason!)
                    let affectedStr = desc(dayAdj.dateAffected!.timeIntervalSince1970)
                    let monthStr = desc(dayAdj.day!.date!.timeIntervalSince1970)
                    let createdStr = desc(dayAdj.dateCreated!.timeIntervalSince1970)
                    
                    if let dayAdjData = encodeItems(amountStr,
                                                      reasonStr,
                                                      affectedStr,
                                                      monthStr,
                                                      createdStr) {
                        os.write(dayAdjData)
                    } else {
                        os.closeFile()
                        return nil
                    }
                }
            } else {
                os.closeFile()
                return nil
            }

            
            // Write expense headers
            os.write("Expenses\r\n".data(using: encoding)!)
            if let expenseHeaders = encodeItems("amount", "shortDescription", "notes", "day", "dateCreated") {
                os.write(expenseHeaders)
            } else {
                os.closeFile()
                return nil
            }
            
            let expenseReq: NSFetchRequest<Expense> = Expense.fetchRequest()
            let expenseSortDesc = NSSortDescriptor(key: "dateCreated_", ascending: true)
            expenseReq.sortDescriptors = [expenseSortDesc]
            if let expenses = try? context.fetch(expenseReq) {
                for expense in expenses {
                    let amountStr = desc(expense.amount!)
                    let descStr = desc(expense.shortDescription!)
                    let notesStr = desc(expense.notes ?? "" )
                    let dayStr = desc(expense.day!.date!.timeIntervalSince1970)
                    let createdStr = desc(expense.dateCreated!.timeIntervalSince1970)
                    
                    if let expenseData = encodeItems(amountStr,
                                                    descStr,
                                                    notesStr,
                                                    dayStr,
                                                    createdStr) {
                        os.write(expenseData)
                    } else {
                        os.closeFile()
                        return nil
                    }
                }
            } else {
                os.closeFile()
                return nil
            }
            
            os.closeFile()
            return URL(fileURLWithPath: filePath)
            
        } else {
            return nil
        }
    }
}

class Importer {
    class func importUrl(_ url: URL) -> Bool {
        return false
    }
}
