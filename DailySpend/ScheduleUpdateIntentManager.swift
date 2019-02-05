//
//  ScheduleUpdateIntent.swift
//  DailySpend
//
//  Created by Josh Sherick on 2/3/19.
//  Copyright © 2019 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

class ScheduleUpdateIntentManager {
    let present: (UIViewController, Bool, (() -> Void)?) -> ()
    let context: NSManagedObjectContext
    let goal: Goal!
    let current: StagedPaySchedule
    let delegate: ScheduleUpdateIntentManagerDelegate

    init(
        context: NSManagedObjectContext,
        goalId: NSManagedObjectID,
        current: StagedPaySchedule,
        delegate: ScheduleUpdateIntentManagerDelegate,
        present: @escaping (UIViewController, Bool, (() -> Void)?) -> ()
    ) {
        self.present = present
        self.context = context
        self.goal = Goal.inContext(goalId) // Main context goal
        self.current = current
        self.delegate = delegate
    }

    /**
     * This function returns `true` if the user may have intended to start this
     * schedule on a different day, and it is possible to automatically create
     * the schedule they may have wanted.
     *
     * Specifically, the user must not have changed the start and end,
     * the schedule must be currently active, the
     */
    func shouldPromptForMinorInitialScheduleUpdateIntent() -> Bool {
        guard let initialPeriod = goal.getInitialPeriod(style: .period),
            let cleanInitialSchedule = goal.activePaySchedule(on: initialPeriod.start),
            let firstPeriodInSchedule = GoalPeriod(goal: goal, date: cleanInitialSchedule.start!, style: .period)
        else {
                return false
        }

        let today = CalendarDay().start
        let clean = StagedPaySchedule.from(cleanInitialSchedule)
        // Must be in the current schedue, start must be after today,
        // start and end must not have changed, and there must be some
        // difference between the current (edited) and clean versions.
        let passesCommonChecks = initialPeriod.contains(date: today) &&
            clean.start != nil &&
            clean.start?.gmtDate != today.gmtDate &&
            current.start?.gmtDate == clean.start?.gmtDate &&
            current.end?.gmtDate == clean.end?.gmtDate &&
            current != clean

        // Period must have changed.
        let passesNonRecurringChecks = current.period != clean.period

        // Check that the schedule is recurring, it's period did not change,
        // it's not the first period in it's schedule and it's not the last
        // period in it's schedule.
        let passesRecurringChecks = clean.period.scope != .None &&
            current.period == clean.period &&
            !firstPeriodInSchedule.contains(date: today) &&
            (
                clean.exclusiveEnd == nil ||
                clean.exclusiveEnd!.gmtDate > initialPeriod.end!.gmtDate
            )

        return passesCommonChecks && (passesNonRecurringChecks || passesRecurringChecks)
    }

    /**
     * Prompts the user to ensure they want the settings they saved their
     * schedule with, makes any necessary changes, validates those changes,
     * saves, and performs post save actions.
     *
     * Should only be called if shouldPromptForMinorInitialScheduleUpdateIntent
     * evaluates to true.
     */
    func promptForMinorInitialScheduleUpdateIntent(context: NSManagedObjectContext) {
        guard let initialPeriod = goal.getInitialPeriod(style: .period),
              let cleanInitialSchedule = goal.activePaySchedule(on: initialPeriod.start)
            else {
                Logger.debug("Failed to set up cleanInitialSchedule to check for minor change.")
                return
        }
        let df = DateFormatter.shortDate()
        let initialStartString = current.start!.string(formatter: df)
        let actionSheetMessage = "Making this change will affect all balances " +
            "since \(initialStartString). Are you sure this is when you'd " +
            "like your changes to take effect?"

        let actionSheet = UIAlertController(
            title: "Effective Date",
            message: actionSheetMessage,
            preferredStyle: .actionSheet
        )

        var actions: [UIAlertAction]

        // Check if we are able to make the changes effective on a period basis.
        let clean = StagedPaySchedule.from(cleanInitialSchedule)
        if clean.period.scope != .None && current.period == clean.period {
            // Period is recurring and did not change, and we already checked
            // other necessary conditions in
            // shouldPromptForMinorInitialScheduleUpdateIntent
            actions = getNoPeriodChangeActions(
                context: context,
                initialPeriod: initialPeriod
            )
        } else {
            actions = getPeriodChangeActions(
                context: context,
                initialPeriod: initialPeriod
            )
        }

        let lastTwoActions = [
            UIAlertAction(
                title: "Yes, take effect \(initialStartString)",
                style: .default,
                handler: { _ in
                    self.delegate.saveWithoutChanges(context: context, goal: self.goal)
                }
            ),
            UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: { _ in
                    self.delegate.cancel(context: context)
                }
            ),
            ]

        actionSheet.addActions(actions)
        actionSheet.addActions(lastTwoActions)
        self.present(actionSheet, true, nil)
    }

    private func getNoPeriodChangeActions(
        context: NSManagedObjectContext,
        initialPeriod: GoalPeriod
    ) -> [UIAlertAction] {
        let df = DateFormatter.shortDate()

        let scope = current.period.scope
        var currentString = "No, take effect "
        var nextString = "No, take effect "
        if current.period.multiplier == 1 {
            currentString += scope.currentString().lowercased()
            nextString += scope.nextString().lowercased()
        } else {
            let currentPeriodStartString = initialPeriod.start.string(formatter: df)
            let nextPeriodStartString = initialPeriod.end!.string(formatter: df)
            currentString += "this period (\(currentPeriodStartString))"
            nextString += "this period (\(nextPeriodStartString))"
        }

        let actions = [
            UIAlertAction(
                title: currentString,
                style: .default,
                handler: { _ in
                    self.delegate.saveAfterCreatingCopiedScheduleWithStart(initialPeriod.start, context: context, goal: self.goal, initialPeriod: initialPeriod)
                }
            ),
            UIAlertAction(
                title: nextString,
                style: .default,
                handler: { _ in
                    self.delegate.saveAfterCreatingCopiedScheduleWithStart(initialPeriod.end!, context: context, goal: self.goal, initialPeriod: initialPeriod)
                }
            ),
        ]

        return actions
    }

    private func getPeriodChangeActions(
        context: NSManagedObjectContext,
        initialPeriod: GoalPeriod
    ) -> [UIAlertAction] {
        let actions = [
            UIAlertAction(
                title: "No, take effect today",
                style: .default,
                handler: { _ in
                    self.delegate.saveAfterCreatingCopiedScheduleWithStart(CalendarDay().start, context: context, goal: self.goal, initialPeriod: initialPeriod)
                }
            )
        ]
        return actions
    }
}

protocol ScheduleUpdateIntentManagerDelegate {
    func saveAfterCreatingCopiedScheduleWithStart(_ start: CalendarDateProvider, context: NSManagedObjectContext, goal: Goal, initialPeriod: GoalPeriod)
    func saveWithoutChanges(context: NSManagedObjectContext, goal: Goal)
    func cancel(context: NSManagedObjectContext)
}
