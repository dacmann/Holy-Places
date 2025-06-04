//
//  RuntimeManager.swift
//  Holy Places
//
//  Created by Derek Cordon on 5/26/25.
//  Copyright © 2025 Derek Cordon. All rights reserved.
//
import Foundation
import WatchKit

class RuntimeManager: NSObject, WKExtendedRuntimeSessionDelegate {
    static let shared = RuntimeManager()

    private var session: WKExtendedRuntimeSession?

    func start() {
        guard session == nil else { return }
        session = WKExtendedRuntimeSession()
        session?.delegate = self
        session?.start()
    }

    func stop() {
        session?.invalidate()
        session = nil
    }

    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        print("🟢 Extended runtime session started")
    }

    func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        print("⚠️ Extended runtime session will expire soon")
    }

    func extendedRuntimeSession(_ session: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("🔴 Extended runtime session ended: \(reason)")
        if let error = error {
            print("Runtime session error: \(error.localizedDescription)")
        }

        // Optionally auto-restart if it ended naturally
        if reason != .error {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.start()
            }
        }

        self.session = nil
    }
}


