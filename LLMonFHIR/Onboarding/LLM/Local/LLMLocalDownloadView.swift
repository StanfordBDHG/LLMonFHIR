//
// This source file is part of the Stanford HealthGPT project
//
// SPDX-FileCopyrightText: 2024 Stanford University & Project Contributors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMLocalDownload
import SpeziOnboarding
import SwiftUI


struct LLMLocalDownloadView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath


    var body: some View {
        SpeziLLMLocalDownload.LLMLocalDownloadView(
            downloadDescription: "LLAMA2_DOWNLOAD_DESCRIPTION",
            llmDownloadUrl: LLMLocalDownloadManager.LLMUrlDefaults.llama2ChatModelUrl,
            llmStorageUrl: .cachesDirectory.appending(path: "llm.gguf")
        ) {
            onboardingNavigationPath.nextStep()
        }
    }
}


#Preview {
    LLMLocalDownloadView()
}
