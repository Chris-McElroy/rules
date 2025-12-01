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
        if savedTimes.last == 0 {
            savedTimes.removeLast()
            Storage.set(savedTimes, for: .times)
        }
    }
    
    func format(time: TimeInterval) -> String {
        let current = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date.now)
        let given = Calendar.current.dateComponents([.weekday, .year, .month, .day, .hour, .minute],
                                                    from: Date.init(timeIntervalSinceReferenceDate: abs(time)))
        
        var formattedTime = ""
        
        if current.year != given.year {
            formattedTime += (
                dayLetter(given.weekday ?? 1) +
                String((given.year ?? 1997) - 1997) + "." +
                String(given.month ?? 1) + "." +
                String(given.day ?? 1) + "." +
                String(given.hour ?? 0) + "." +
                String(given.minute ?? 0)
            )
        } else if current.month != given.month {
            formattedTime += (
                dayLetter(given.weekday ?? 1) + "." +
                String(given.month ?? 1) + "." +
                String(given.day ?? 1) + "." +
                String(given.hour ?? 0) + "." +
                String(given.minute ?? 0)
            )
        } else if current.day != given.day {
            formattedTime += (
                dayLetter(given.weekday ?? 1) + ":" +
                String(given.day ?? 1) + "." +
                String(given.hour ?? 0) + "." +
                String(given.minute ?? 0)
            )
        } else {
            formattedTime += (
                "," +
                String(given.hour ?? 0) + "." +
                String(given.minute ?? 0)
            )
        }
        
        return formattedTime
    }
    
    func dayLetter(_ day: Int) -> String {
        switch day {
        case 1: return "u"
        case 2: return "m"
        case 3: return "t"
        case 4: return "w"
        case 5: return "r"
        case 6: return "f"
        default: return "s"
        }
    }
    
    func recordTime(_ success: Bool) {
        savedTimes.insert(success ? Date.timeIntervalSinceReferenceDate : -Date.timeIntervalSinceReferenceDate, at: 0)
        Storage.set(savedTimes, for: .times)
        scheduleCheckins()
    }
    
    func scheduleCheckins() {
        let timeSincelastFail: TimeInterval = Date.timeIntervalSinceReferenceDate + (savedTimes.first(where: { $0 < 0 }) ?? 0)
        let reminderInterval: TimeInterval
        
        switch timeSincelastFail {
        case 0..<604800: reminderInterval = 3600
        case 604800..<18144000: reminderInterval = 86400
        case 18144000..<220752000: reminderInterval = 604800
        default: reminderInterval = 18144000
        }
        
        let timeSinceLastCheckin = Date.timeIntervalSinceReferenceDate - abs(savedTimes.first ?? 0)
        let timesUntilCheckins = stride(from: 0, to: 12, by: 1).map { max(60, reminderInterval - timeSinceLastCheckin) + 3600*$0 }
        
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
        
        for time in timesUntilCheckins {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: trigger)
            notificationCenter.add(request)
        }
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
        scheduleCheckins()
        completionHandler()
    }
    
    func setUpNotifications() {
        notificationCenter.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        print("success!")
                        self.scheduleCheckins()
                    } else if let error {
                        print(error.localizedDescription)
                    }
                }
            } else if settings.authorizationStatus == .authorized {
                self.scheduleCheckins()
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
