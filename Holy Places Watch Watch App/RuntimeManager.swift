//
//  RuntimeManager.swift
//  Holy Places
//
//  Created by Derek Cordon on 5/26/25.
//  Copyright © 2025 Derek Cordon. All rights reserved.
//
import Foundation
import WatchKit
import UserNotifications

class RuntimeManager: NSObject, WKExtendedRuntimeSessionDelegate {
    static let shared = RuntimeManager()

    private var session: WKExtendedRuntimeSession?

    func start() {
        if session == nil || session?.state != .running {
            session = WKExtendedRuntimeSession()
            session?.delegate = self
            session?.start()
        }
    }

    func stop() {
        session?.invalidate()
        session = nil
    }

    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        print("🟢 Extended runtime session started. State: \(session.state.rawValue)")
    }

    func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        print("⚠️ Extended runtime session will expire soon")
        // Play a haptic to alert the user
        WKInterfaceDevice.current().play(.notification)
        // Schedule a Time Sensitive local notification to prompt user interaction
        let content = UNMutableNotificationContent()
        content.title = "Holy Places Timer"
        content.body = "Your timer session is about to expire. Tap to continue."
        content.sound = .default
        content.interruptionLevel = .timeSensitive // Set as Time Sensitive
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule Time Sensitive notification: \(error.localizedDescription)")
            }
        }
    }

    func extendedRuntimeSession(_ session: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("🔴 Extended runtime session ended: \(reason)")
        if let error = error {
            print("Runtime session error: \(error.localizedDescription)")
        }
        // Auto-restart session after a short delay if not due to error
        if reason != .error {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // Check if app is still in foreground or frontmost
                if WKExtension.shared().applicationState != .background {
                    self.start()
                } else {
                    // Schedule a Time Sensitive notification to bring the app back to foreground
                    let content = UNMutableNotificationContent()
                    content.title = "Holy Places Timer"
                    content.body = "Timer session ended. Open the app to continue."
                    content.sound = .default
                    content.interruptionLevel = .timeSensitive // Set as Time Sensitive
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Failed to schedule Time Sensitive notification: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        self.session = nil
    }
}
