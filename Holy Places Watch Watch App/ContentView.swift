// ContentView.swift
// Holy Places Watch Extension

import SwiftUI
import WatchKit
import UserNotifications

struct ContentView: View {

    @State private var showIntro = false
    @State private var dontShowAgain = false
    @State private var showSwipeHint = true
    @State private var countdown: Int = 600 // in seconds
    @State private var timer: Timer?
    @State private var isTapping = false
    @State private var hapticTimer: Timer?
    private let selectedMinutesKey = "selectedMinutes"
    @State private var selectedMinutes = UserDefaults.standard.integer(forKey: "selectedMinutes") == 0
        ? 10 : UserDefaults.standard.integer(forKey: "selectedMinutes")

    @State private var showPicker = false
    @State private var backgroundIndex = UserDefaults.standard.integer(forKey: "backgroundIndex")
    let backgrounds = ["celestial", "tree_of_life_garden", "mountain_of_the_lord"]
    @State private var countdownFontSize: CGFloat = 16

    
    var body: some View {
        ZStack {
            Image(backgrounds[backgroundIndex])
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                // Fixed height container to avoid layout thrashing
                ZStack {
                    if showPicker {
                        HStack(spacing: 20) {
                            Button(action: {
                                adjustMinutes(-1)
                            }) {
                                Image(systemName: "minus.circle")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                                    adjustMinutes(-5)
                                }
                            )

                            Text("\(selectedMinutes) min")
                                .font(.caption2)
                                .foregroundColor(.white)

                            Button(action: {
                                adjustMinutes(1)
                            }) {
                                Image(systemName: "plus.circle")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                                    adjustMinutes(5)
                                }
                            )

                        }
                        .padding()
                        .padding(.top, 40) // 👈 pushes the stepper down a bit
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else if showSwipeHint {
                        Text("Swipe down to adjust timer\nSwipe left/right to change image")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.top, 44)
                            .frame(maxWidth: .infinity)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }

                .frame(height: 60)
                
                Spacer()
                
                Text(timerText())
                    .font(.system(size: countdownFontSize))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 20)
                    .if(!showPicker) { view in
                        view
                            .focusable(true)
                            .digitalCrownRotation(
                                $countdownFontSize,
                                from: 10,
                                through: 40,
                                by: 1,
                                sensitivity: .medium,
                                isContinuous: false,
                                isHapticFeedbackEnabled: true
                            )
                            .onChange(of: countdownFontSize) {
                                UserDefaults.standard.set(Float(countdownFontSize), forKey: "countdownFontSize")
                            }
                    }
            }
            .padding()
        }
        
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("Notification authorization error: \(error.localizedDescription)")
                }
                if !granted {
                    print("Notifications denied. Users won’t receive session expiration alerts in the background.")
                    // Optionally set a @State variable to show a UI warning, e.g.:
                    // self.showNotificationWarning = true
                }
            }
            countdownFontSize = CGFloat(UserDefaults.standard.float(forKey: "countdownFontSize") == 0 ? 16 : UserDefaults.standard.float(forKey: "countdownFontSize"))

            if !UserDefaults.standard.bool(forKey: "hasSeenIntro") {
                showIntro = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showSwipeHint = false
                }
            }
            RuntimeManager.shared.start()
            startCountdown()
        }
        .onTapGesture {
            if isTapping {
                resetCountdown()
            }
        }
        .sheet(isPresented: $showIntro) {
            IntroContentView(dontShowAgain: $dontShowAgain) {
                if dontShowAgain {
                    UserDefaults.standard.set(true, forKey: "hasSeenIntro")
                }
                showIntro = false
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    if abs(value.translation.width) > abs(value.translation.height) {
                        if value.translation.width < 0 {
                            backgroundIndex = (backgroundIndex + 1) % backgrounds.count
                            UserDefaults.standard.set(backgroundIndex, forKey: "backgroundIndex")
                        } else if value.translation.width > 0 {
                            backgroundIndex = (backgroundIndex - 1 + backgrounds.count) % backgrounds.count
                            UserDefaults.standard.set(backgroundIndex, forKey: "backgroundIndex")
                        }
                    } else {
                        if value.translation.height > 0 {
                            withAnimation {
                                showPicker = true
                            }
                        } else if value.translation.height < 0 {
                            withAnimation {
                                showPicker = false
                            }
                        }
                    }
                }
        )

    }
    
    func adjustMinutes(_ delta: Int) {
        let newValue = max(1, min(60, selectedMinutes + delta))
        if newValue != selectedMinutes {
            selectedMinutes = newValue
            WKInterfaceDevice.current().play(.click)
            UserDefaults.standard.set(selectedMinutes, forKey: selectedMinutesKey)
            resetCountdown()
        }
    }
    
    func timerText() -> String {
        let minutes = countdown / 60
        let seconds = countdown % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func startCountdown() {
        WKInterfaceDevice.current().play(.start)
        stopTimers()
        isTapping = false
        countdown = selectedMinutes * 60
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            countdown -= 1
            if countdown <= 0 {
                startTapping()
            }
        }
    }
    
    func resetCountdown() {
        stopTapping()
        startCountdown()
    }
    
    func startTapping() {
        isTapping = true
        timer?.invalidate()
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            WKInterfaceDevice.current().play(.notification)
        }
    }
    
    func stopTapping() {
        isTapping = false
        hapticTimer?.invalidate()
        hapticTimer = nil
    }
    
    func stopTimers() {
        timer?.invalidate()
        hapticTimer?.invalidate()
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, apply: (Self) -> Content) -> some View {
        if condition {
            apply(self)
        } else {
            self
        }
    }
}

private struct IntroContentView: View {
    @Binding var dontShowAgain: Bool
    var onDismiss: () -> Void

    var body: some View {
        ScrollView {
            InnerIntroViewContent(
                dontShowAgain: $dontShowAgain,
                onDismiss: onDismiss
            )
        }
    }
}

private struct InnerIntroViewContent: View {
    @Binding var dontShowAgain: Bool
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Holy Places Timer")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.top)

            Text("Gently reminds you to stay alert while serving in the temple. Swipe down to change the interval, swipe sideways to change the background, turn the Digital Crown to adjust the timer font, and tap the screen to reset the expired timer.")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
            
            Text("This app runs for up to 1 hour. Enable Notifications when prompted to receive alerts if the timer stops. Turn on Time Sensitive Notifications in the Watch app to ensure timely delivery, even in Do Not Disturb mode.")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            Toggle("Don't show again", isOn: $dontShowAgain)
                .padding(.horizontal)

            Button("OK") {
                onDismiss()
            }
            .padding(.bottom)
        }
        .padding()
    }
}






