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

    /// True when a session has been created and start() called, but extendedRuntimeSessionDidStart
    /// has not yet fired. Prevents creating another session during this window.
    private var isStarting = false

    func start() {
        // Already running or in the process of starting – nothing to do
        if isStarting { return }
        if let s = session, s.state == .running { return }

        // Release any previous (invalidated) session reference
        session = nil
        isStarting = true

        // Create and start on the next run-loop so any prior session dealloc can finish
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isStarting else { return }
            self.session = WKExtendedRuntimeSession()
            self.session?.delegate = self
            self.session?.start()
        }
    }

    func stop() {
        isStarting = false
        session?.invalidate()
        session = nil
    }

    // MARK: - Delegate

    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        isStarting = false
        print("🟢 Extended runtime session started. State: \(session.state.rawValue)")
    }

    func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        print("⚠️ Extended runtime session will expire soon")
        WKInterfaceDevice.current().play(.notification)
        let content = UNMutableNotificationContent()
        content.title = "Holy Places Timer"
        content.body = "Your timer session is about to expire. Tap to continue."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        let request = UNNotificationRequest(
            identifier: "HolyPlacesWatch_willExpire",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    func extendedRuntimeSession(_ session: WKExtendedRuntimeSession,
                                didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                error: Error?) {
        print("🔴 Extended runtime session ended: reason=\(reason.rawValue)")
        if let error = error {
            print("   error: \(error.localizedDescription)")
        }
        isStarting = false
        self.session = nil
        // Do NOT auto-retry here.  The next scenePhase → .active will call start().
        // Retrying here caused an infinite loop when the system rejected new sessions.
    }
}
