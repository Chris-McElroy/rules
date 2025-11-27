//
//  Times.swift
//  rules
//
//  Created by 4 on '25.11.27.
//

import SwiftUI
import UserNotifications
import Combine

class Times: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static var main = Times()
    
    @Published var savedTimes: [TimeInterval] = Storage.getSavedTimes()
    @Published var oldTimes: [[TimeInterval]] = []
    
    let notificationCenter = UNUserNotificationCenter.current()
    let notificationContent = getNotificationContent()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setUpNotifications()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "yes":
            savedTimes.insert(Date.timeIntervalSinceReferenceDate, at: 0)
            Storage.set(savedTimes, for: .times)
        case "no":
            savedTimes.insert(-Date.timeIntervalSinceReferenceDate, at: 0)
            Storage.set(savedTimes, for: .times)
        default:
            break
        }
        scheduleNextCheckin()
        completionHandler()
    }
    
    func recordTime(_ success: Bool) {
        savedTimes.insert(success ? Date.timeIntervalSinceReferenceDate : -Date.timeIntervalSinceReferenceDate, at: 0)
        Storage.set(savedTimes, for: .times)
        scheduleNextCheckin()
    }
    
    func scheduleNextCheckin() {
        let timeSincelastFail: TimeInterval = Date.timeIntervalSinceReferenceDate + (savedTimes.first(where: { $0 < 0 }) ?? 0)
        let reminderInterval: TimeInterval
        
        switch timeSincelastFail {
        case 0..<604800: reminderInterval = 3600
        case 604800..<18144000: reminderInterval = 86400
        case 18144000..<220752000: reminderInterval = 604800
        default: reminderInterval = 18144000
        }
        
        let timeSinceLastCheckin = Date.timeIntervalSinceReferenceDate - abs(savedTimes.first ?? 0)
        let timeUntilReminder = max(900, reminderInterval - timeSinceLastCheckin)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeUntilReminder, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: trigger)

        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.add(request)
    }
    
    func setUpNotifications() {
        notificationCenter.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        print("success!")
                        self.scheduleNextCheckin()
                    } else if let error {
                        print(error.localizedDescription)
                    }
                }
            } else if settings.authorizationStatus == .authorized {
                self.scheduleNextCheckin()
            }
        }
    }
    
    static func getNotificationContent() -> UNNotificationContent {
        let yes = UNNotificationAction(identifier: "yes", title: "yes", options: .authenticationRequired)
        let no = UNNotificationAction(identifier: "no", title: "no", options: .authenticationRequired)
        let options = UNNotificationCategory(identifier: "options", actions: [yes, no], intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([options])
        
        let content = UNMutableNotificationContent()
        content.title = "check in time!"
        content.subtitle = "have you been following your rules?"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "options"
        return content
    }
}
