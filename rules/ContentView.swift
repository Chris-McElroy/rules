//
//  ContentView.swift
//  rules
//
//  Created by 4 on '25.11.25.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @State var savedTimes: [TimeInterval] = Storage.getSavedTimes()
    @State var oldTimes: [[TimeInterval]] = []
    
    let formatter = DateFormatter()
    
    init() {
        formatter.dateFormat = ".M.d.H.m"
    }
    
    var body: some View {
        VStack(spacing: 30) {
            List() {
                ForEach($savedTimes, id: \.self) { time in
                    HStack {
                        Spacer()
                        if time.wrappedValue != 0 {
                            Image(systemName: time.wrappedValue > 0 ? "checkmark.seal.fill" : "xmark.seal")
                            Text(formatter.string(from: Date(timeIntervalSinceReferenceDate: abs(time.wrappedValue))))
                        } else if !oldTimes.isEmpty {
                            Text("undo")
                                .onTapGesture {
                                    savedTimes = oldTimes.popLast() ?? []
                                    if oldTimes.isEmpty {
                                        if savedTimes.last == 0 {
                                            savedTimes.removeLast()
                                        }
                                    }
                                    Storage.set(savedTimes, for: .times)
                                }
                        }
                        Spacer()
                    }
                    .deleteDisabled(time.wrappedValue == 0)
                }
                .onDelete { toDelete in
                    oldTimes.append(savedTimes)
                    savedTimes.remove(atOffsets: toDelete)
                    if savedTimes.last != 0 {
                        savedTimes.append(0)
                    }
                    Storage.set(savedTimes, for: .times)
                }
                .listRowSeparator(.hidden)
            }
            Text("following since " + formatter.string(from: Date.init(timeIntervalSinceReferenceDate: abs(savedTimes.first ?? 0))) + "?")
            HStack(spacing: 75) {
                Image(systemName: "checkmark.seal.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .onTapGesture {
                        recordTime(true)
                        
                    }
                Image(systemName: "xmark.seal")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .onTapGesture {
                        recordTime(false)
                    }
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            if oldTimes.isEmpty {
                if savedTimes.last == 0 {
                    savedTimes.removeLast()
                }
            }
            Storage.set(savedTimes, for: .times)
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                if settings.authorizationStatus == .notDetermined {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                        if success {
                            print("success!")
                            scheduleNextCheckin()
                        } else if let error {
                            print(error.localizedDescription)
                        }
                    }
                } else if settings.authorizationStatus == .authorized {
                    scheduleNextCheckin()
                }
            }
        }
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
        
        let content = UNMutableNotificationContent()
        content.title = "check in time!"
        content.subtitle = "have you been following your rules?"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeUntilReminder, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        UNUserNotificationCenter.current().add(request)
    }
}
