//
//  InfoView.swift
//  Holy Places
//
//  Created by Derek Cordon on 6/12/26.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI
import MessageUI
import SafariServices

// MARK: - Main View

struct InfoView: View {
    let onDismiss: () -> Void

    @State private var showFairMormon = false
    @State private var showFAQ = false
    @State private var showMail = false
    @State private var showMailUnavailableAlert = false

    private var versionString: String {
        let appVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? ""
        let dataVersion = placeDataVersion ?? ""
        return "Version: \(appVersion) | \(dataVersion)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    greetingRow
                    Divider()
                    logoDescriptionSection
                    Divider()
                    quizGameSection
                    Divider()
                    footerSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("Holy Places of the Lord")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onDismiss) {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showFairMormon) {
            if let url = URL(string: "http://oneclimbs.com/2011/11/21/restoring-the-pentagram-to-its-proper-place/") {
                SafariView(url: url)
            }
        }
        .sheet(isPresented: $showFAQ) {
            if let url = URL(string: "https://dacworld.net/holyplaces/holyplacesfaq.html") {
                SafariView(url: url)
            }
        }
        .sheet(isPresented: $showMail) {
            MailView(
                recipient: "dacmann@icloud.com",
                subject: "Holy Places App Feedback",
                body: "<br><br><br><p>----------------------</p><p>Device: \(UIDevice.current.modelName) </p><p> \(versionString) </p><p>----------------------</p>"
            )
        }
        .alert("Mail Unavailable", isPresented: $showMailUnavailableAlert) {
            Button("Open Mail App") {
                if let url = URL(string: "mailto:dacmann@icloud.com?subject=Holy%20Places%20App%20Feedback") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The default Mail app is not configured on this device.")
        }
    }

    // MARK: - Subviews

    private var greetingRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("Greetings! Creating and maintaining this app is a labor of love. I hope it assists and motivates all who use it to frequently visit these Holy Places.\n\n  - Derek")
                .font(.custom("Baskerville", size: 23))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                Image("profile 1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Button("Contact Me") {
                    if MFMailComposeViewController.canSendMail() {
                        showMail = true
                    } else {
                        showMailUnavailableAlert = true
                    }
                }
                .font(.custom("Baskerville", size: 20))
                .foregroundColor(Color("BaptismsBlue"))

                Button("FAQ") {
                    showFAQ = true
                }
                .font(.custom("Baskerville", size: 20))
                .foregroundColor(Color("BaptismsBlue"))
            }
            .frame(width: 120)
        }
    }

    private var logoDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image("morningstarmoroni")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .darkBackgroundLogoGlow()

                Text("The Holy Places logo, created by my daughter, features the Morning Star from the Nauvoo Temple's stained glass windows along with the Angel Moroni. It represents both the app's historical and temple aspects. One Climbs has a great article on the inverted five-pointed star's use on temples.")
                    .font(.custom("Baskerville", size: 20))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("Article on Inverted Star") {
                showFairMormon = true
            }
            .font(.custom("Baskerville", size: 20))
            .foregroundColor(Color("BaptismsBlue"))
            .frame(maxWidth: .infinity)
        }
    }

    private var quizGameSection: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image("QuizGame")
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .frame(width: 70, height: 70)
                    .darkBackgroundLogoGlow()

                Text("See how well you know your stuff with my fun Holy Places Quiz Game app for iPhone, iPad and the Apple TV.")
                    .font(.custom("Baskerville", size: 20))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button("Holy Places Quiz Game") {
                if let url = URL(string: "https://apps.apple.com/app/id1294022470") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.custom("Baskerville", size: 20))
            .foregroundColor(Color("BaptismsBlue"))
            .frame(maxWidth: .infinity)
        }
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text(versionString)
                .font(.custom("Baskerville", size: 17))
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text("Holy Places of the Lord is an independent, unofficial app created by Derek S. Cordon. It is not affiliated with, sponsored by, or endorsed by The Church of Jesus Christ of Latter-day Saints.")
                .font(.custom("Baskerville", size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }
}

// MARK: - Logo glow (dark mode)

struct DarkBackgroundLogoGlow: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content
                .shadow(color: .white.opacity(0.95), radius: 3)
                .shadow(color: .white.opacity(0.55), radius: 8)
                .shadow(color: .white.opacity(0.25), radius: 14)
        } else {
            content
        }
    }
}

extension View {
    func darkBackgroundLogoGlow() -> some View {
        modifier(DarkBackgroundLogoGlow())
    }
}

// MARK: - Safari representable

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Mail representable

struct MailView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = context.coordinator
        mail.setToRecipients([recipient])
        mail.setSubject(subject)
        mail.setMessageBody(body, isHTML: true)
        return mail
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Preview

#Preview {
    InfoView(onDismiss: {})
}
