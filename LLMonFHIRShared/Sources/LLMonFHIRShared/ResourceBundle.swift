//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

private import Foundation
public import class ModelsR4.Bundle
public import class ModelsR4.Patient
private import OSLog


extension ModelsR4.Bundle {
    public enum BundleIdSelector {
        /// A `ModelsR4.Bundle` should be identified by its filepath, relative to the `Synthetic Patients` folder.
        case filePath
        /// A `ModelsR4.Bundle` should be identified by the name of the single patient contained within it.
        case patientName
    }
    
    private static let logger = Logger(subsystem: "edu.stanford.LLMonFHIR.LLMonFHIRShared", category: "ResourceBundleLoading")
    
    public static func named(_ bundleFilename: String) -> ModelsR4.Bundle? {
        allCustomBundles(identifiedBy: .filePath)[bundleFilename]
    }
    
    public static func forPatient(named patientName: String) -> ModelsR4.Bundle? {
        allCustomBundles(identifiedBy: .patientName)[patientName]
    }
    
    
    /// Fetches all bundles located in `LLMonFHIRShared/Resources/Synthetic Patients/`.
    ///
    /// - parameter idSelector: specifies the propertly by which the bundles should be identified.
    /// - returns: A dictionary, mapping each bundle identifier to its bundle.
    public static func allCustomBundles(identifiedBy idSelector: BundleIdSelector) -> [String: ModelsR4.Bundle] {
        guard let synthPatientsUrl = Foundation.Bundle.llmOnFhirShared.url(forResource: "Synthetic Patients", withExtension: nil),
              let enumerator = FileManager.default.enumerator(
                at: synthPatientsUrl,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
              ) else {
            return [:]
        }
        var seenBundleIds: Set<String> = []
        var bundlesById: [String: ModelsR4.Bundle] = [:]
        for url in enumerator.lazy.compactMap({ $0 as? URL }) {
            guard (try? url.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true else {
                continue
            }
            let bundle: ModelsR4.Bundle
            do {
                bundle = try JSONDecoder().decode(ModelsR4.Bundle.self, from: Data(contentsOf: url))
            } catch {
                logger.warning("Skipping FHIR bundle at \(url.path): \(error)")
                continue
            }
            let bundleId: String
            switch idSelector {
            case .filePath:
                bundleId = url.deletingPathExtension().partialPath(relativeTo: synthPatientsUrl)!
            case .patientName:
                guard let name = bundle.singlePatient?.fullName else {
                    logger.warning("Skipping FHIR bundle at \(url.path): no patient, or unable to obtain patient name")
                    continue
                }
                bundleId = name
            }
            guard !seenBundleIds.contains(bundleId) else {
                // we've already seen this bundle id,
                // meaning there exist multiple bundles with this id,
                // meaning that the id cannot be used to uniquely identify the bundle.
                bundlesById[bundleId] = nil
                continue
            }
            seenBundleIds.insert(bundleId)
            bundlesById[bundleId] = bundle
        }
        for duplicateBundleId in seenBundleIds.subtracting(bundlesById.keys) {
            logger.warning("Found multiple bundles with id '\(duplicateBundleId)'. Skipped all of them.")
        }
        return bundlesById
    }
}


extension ModelsR4.Bundle {
    public var singlePatient: ModelsR4.Patient? {
        guard let patients = entry?.compactMap({ $0.resource?.get(if: ModelsR4.Patient.self) }), patients.count == 1 else {
            return nil
        }
        return patients.first
    }
}


extension ModelsR4.Patient {
    public var fullName: String? {
        for name in name ?? [] {
            let familyName = name.family?.value?.string ?? ""
            let givenNames = (name.given?.compactMap { $0.value?.string } ?? []).filter { !$0.isEmpty }
            switch (givenNames.isEmpty, familyName.isEmpty) {
            case (true, true): // we have nothing
                continue
            case (true, false): // we have given names, but no family name
                return givenNames.joined(separator: " ")
            case (false, true): // family name yes given names no
                return familyName
            case (false, false):
                return "\(givenNames.joined(separator: " ")) \(familyName)"
            }
        }
        return nil
    }
}


extension URL {
    /// Forms a path relative to a base url
    ///
    /// Example: `/a/b/c/d/e/f/g.h` relative to base `/a/b/c/` would be `d/e/f/g.h`
    ///
    /// - Note: this assumes that the url is a file url
    fileprivate func partialPath(relativeTo baseUrl: URL) -> String? {
        let ownComponents = self.resolvingSymlinksInPath().absoluteURL.pathComponents
        let baseComponents = baseUrl.resolvingSymlinksInPath().absoluteURL.pathComponents
        guard ownComponents.count >= baseComponents.count, // if the base is longer than the current uwl, it cannot be the same
              ownComponents[0..<baseComponents.count] == baseComponents[...] else {
            return nil
        }
        return ownComponents[baseComponents.count...].joined(separator: "/")
    }
}
