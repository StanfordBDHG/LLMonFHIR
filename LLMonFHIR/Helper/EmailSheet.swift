//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import MessageUI
import SwiftUI
import UniformTypeIdentifiers


struct EmailSheet: UIViewControllerRepresentable {
    typealias UIViewControllerType = MFMailComposeViewController
    
    struct Message: Sendable {
        let recipient: String
        let subject: String
        let body: String
        let attachments: [URL]
    }
    
    static var isAvailable: Bool {
        MFMailComposeViewController.canSendMail()
    }
    
    let message: Message
    let onDismiss: @Sendable (MFMailComposeResult) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let viewController = MFMailComposeViewController()
        viewController.mailComposeDelegate = context.coordinator
        viewController.setToRecipients([message.recipient])
        viewController.setSubject(message.subject)
        viewController.setMessageBody(message.body, isHTML: false)
        for url in message.attachments {
            viewController.addAttachment(url)
        }
        context.coordinator.parent = self
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        context.coordinator.parent = self
    }
}


extension EmailSheet {
    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        fileprivate var parent: EmailSheet?
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: (any Error)?) {
            parent?.onDismiss(result)
        }
    }
}


extension MFMailComposeViewController {
    /// - returns: A `Bool` indicating whether the attachment was successfully added.
    @discardableResult
    func addAttachment(_ url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url) else {
            return false
        }
        self.addAttachmentData(data, mimeType: url.mimeType ?? "application/octet-stream", fileName: url.lastPathComponent)
        return true
    }
}

extension URL {
    var mimeType: String? {
        guard !pathExtension.isEmpty else {
            return nil
        }
        return UTType(filenameExtension: pathExtension)?.preferredMIMEType
    }
}
