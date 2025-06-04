// ContentView.swift
// Holy Places Watch Extension

import SwiftUI
import WatchKit

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
    
    var body: some View {
        ZStack {
            Image("celestial")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                // Fixed height container to avoid layout thrashing
                ZStack {
                    Picker("Minutes", selection: Binding(
                        get: { selectedMinutes },
                        set: { newValue in
                            selectedMinutes = newValue
                            UserDefaults.standard.set(newValue, forKey: selectedMinutesKey)
                            resetCountdown()
                        }
                    )) {
                        ForEach(1..<61) { minute in
                            Text("\(minute) min").tag(minute)
                        }
                    }
                    .labelsHidden()
                    .frame(height: 60)
                    .opacity(showPicker ? 1 : 0)
                    
                    if !showPicker && showSwipeHint {
                        Text("⬇︎ swipe to adjust time")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }
                .frame(height: 60)
                
                Spacer()
                
                Text(timerText())
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .onAppear {
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
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
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
        )
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

            Text("Gently reminds you to stay alert while serving in the temple. You’ll feel a tap at your chosen interval (Swipe down to change interval). Simply tap the screen to reset the timer.")
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






