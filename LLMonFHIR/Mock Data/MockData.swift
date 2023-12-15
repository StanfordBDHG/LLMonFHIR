//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import class ModelsR4.Bundle
import SpeziFHIRMockPatients


extension ModelsR4.Bundle {
    private static var _allen322Ferry570: ModelsR4.Bundle?
    static var allen322Ferry570: ModelsR4.Bundle {
        get async {
            if let allen322Ferry570 = _allen322Ferry570 {
                return allen322Ferry570
            }
            
            let allen322Ferry570 = await Foundation.Bundle.main.loadFHIRBundle(
                withName: "Allen322_Ferry570_ad134528-56a5-35fd-c37f-466ff119c625"
            )
            ModelsR4.Bundle._allen322Ferry570 = allen322Ferry570
            return allen322Ferry570
        }
    }
    
    private static var _beatris270Bogan287: ModelsR4.Bundle?
    static var beatris270Bogan287: ModelsR4.Bundle {
        get async {
            if let beatris270Bogan287 = _beatris270Bogan287 {
                return beatris270Bogan287
            }
            
            let beatris270Bogan287 = await Foundation.Bundle.main.loadFHIRBundle(
                withName: "Beatris270_Bogan287_5b3645de-a2d0-d016-0839-bab3757c4c58"
            )
            ModelsR4.Bundle._beatris270Bogan287 = beatris270Bogan287
            return beatris270Bogan287
        }
    }
    
    private static var _edythe31Morar593: ModelsR4.Bundle?
    static var edythe31Morar593: ModelsR4.Bundle {
        get async {
            if let edythe31Morar593 = _edythe31Morar593 {
                return edythe31Morar593
            }
            
            let edythe31Morar593 = await Foundation.Bundle.main.loadFHIRBundle(
                withName: "Edythe31_Morar593_9c3df38a-d3b7-2198-3898-51f9153d023d"
            )
            ModelsR4.Bundle._edythe31Morar593 = edythe31Morar593
            return edythe31Morar593
        }
    }
    
    private static var _gonzalo160Duenas839: ModelsR4.Bundle?
    static var gonzalo160Duenas839: ModelsR4.Bundle {
        get async {
            if let gonzalo160Duenas839 = _gonzalo160Duenas839 {
                return gonzalo160Duenas839
            }
            
            let gonzalo160Duenas839 = await Foundation.Bundle.main.loadFHIRBundle(
                withName: "Gonzalo160_Duenas839_ed70a28f-30b2-acb7-658a-8b340dadd685"
            )
            ModelsR4.Bundle._gonzalo160Duenas839 = gonzalo160Duenas839
            return gonzalo160Duenas839
        }
    }
    
    private static var _jacklyn830Veum823: ModelsR4.Bundle?
    static var jacklyn830Veum823: ModelsR4.Bundle {
        get async {
            if let jacklyn830Veum823 = _jacklyn830Veum823 {
                return jacklyn830Veum823
            }
            
            let jacklyn830Veum823 = await Foundation.Bundle.main.loadFHIRBundle(
                withName: "Jacklyn830_Veum823_e0e1f21a-22a7-d166-7bb1-63f6bbce1a32"
            )
            ModelsR4.Bundle._jacklyn830Veum823 = jacklyn830Veum823
            return jacklyn830Veum823
        }
    }
    
    private static var _milton509Ortiz186: ModelsR4.Bundle?
    static var milton509Ortiz186: ModelsR4.Bundle {
        get async {
            if let milton509Ortiz186 = _milton509Ortiz186 {
                return milton509Ortiz186
            }
            
            let milton509Ortiz186 = await Foundation.Bundle.main.loadFHIRBundle(
                withName: "Milton509_Ortiz186_d66b5418-06cb-fc8a-8c13-85685b6ac939"
            )
            ModelsR4.Bundle._milton509Ortiz186 = milton509Ortiz186
            return milton509Ortiz186
        }
    }
    
    
    static var llmOnFHIRMockPatients: [Bundle] {
        get async {
            await [
                .allen322Ferry570,
                .beatris270Bogan287,
                .edythe31Morar593,
                .gonzalo160Duenas839,
                .jacklyn830Veum823,
                .milton509Ortiz186
            ]
        }
    }
}
