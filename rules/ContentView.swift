//
//  ContentView.swift
//  rules
//
//  Created by 4 on '25.11.25.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @ObservedObject var times = Times.main
    
    var body: some View {
        VStack(spacing: 30) {
            List() {
                ForEach($times.savedTimes, id: \.self) { time in
                    HStack {
                        Spacer()
                        if time.wrappedValue != 0 {
                            Image(systemName: time.wrappedValue > 0 ? "checkmark.seal.fill" : "xmark.seal")
                            Text(times.format(time: time.wrappedValue))
                        } else if !times.oldTimes.isEmpty {
                            Text("undo")
                                .onTapGesture {
                                    times.savedTimes = times.oldTimes.popLast() ?? []
                                    if times.oldTimes.isEmpty {
                                        if times.savedTimes.last == 0 {
                                            times.savedTimes.removeLast()
                                        }
                                    }
                                    Storage.set(times.savedTimes, for: .times)
                                }
                        }
                        Spacer()
                    }
                    .deleteDisabled(time.wrappedValue == 0)
                }
                .onDelete { toDelete in
                    times.oldTimes.append(times.savedTimes)
                    times.savedTimes.remove(atOffsets: toDelete)
                    if times.savedTimes.last != 0 {
                        times.savedTimes.append(0)
                    }
                    Storage.set(times.savedTimes, for: .times)
                }
                .listRowSeparator(.hidden)
            }
            Text("following since " + times.format(time: times.savedTimes.first ?? 0) + "?")
                .font(Font.custom("Baskerville", size: 20.0))
            HStack(spacing: 75) {
                Image(systemName: "xmark.seal")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .onTapGesture {
                        times.recordTime(false)
                    }
                Image(systemName: "checkmark.seal.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .onTapGesture {
                        times.recordTime(true)
                    }
            }
            .padding(.bottom, 40)
        }
        .font(Font.custom("Baskerville", size: 18.0))
    }
}
