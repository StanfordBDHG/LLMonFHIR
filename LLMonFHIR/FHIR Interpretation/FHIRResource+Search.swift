////
//// This source file is part of the Stanford LLM on FHIR project
////
//// SPDX-FileCopyrightText: 2023 Stanford University
////
//// SPDX-License-Identifier: MIT
////
//
//
// extension FHIRResource {
//    func matchesDisplayName(with searchText: String) -> Bool {
//        let formattedSearchText = searchText
//            .trimmingCharacters(in: .whitespacesAndNewlines)
//            .lowercased()
//        return displayName.lowercased().contains(formattedSearchText)
//    }
// }
//
// extension Array where Element == FHIRResource {
//    func filterByDisplayName(with searchText: String) -> [FHIRResource] {
//        if searchText.isEmpty {
//            return self
//        }
//
//        return filter { resource in
//            resource.matchesDisplayName(with: searchText)
//        }
//    }
// }
