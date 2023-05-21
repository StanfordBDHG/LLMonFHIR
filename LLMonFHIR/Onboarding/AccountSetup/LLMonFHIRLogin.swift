//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziAccount
import SpeziOnboarding
import SwiftUI


struct LLMonFHIRLogin: View {
    var body: some View {
        Login {
            IconView()
                .padding(.top, 32)
            Text("LOGIN_SUBTITLE")
                .multilineTextAlignment(.center)
                .padding()
                .padding()
            Spacer(minLength: 0)
        }
            .navigationBarTitleDisplayMode(.large)
    }
}


#if DEBUG
struct LLMonFHIRLogin_Previews: PreviewProvider {
    static var previews: some View {
        LLMonFHIRLogin()
            .environmentObject(Account(accountServices: []))
    }
}
#endif
