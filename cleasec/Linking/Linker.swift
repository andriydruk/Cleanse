//
//  Linker.swift
//  cleasec
//
//  Created by Sebastian Edward Shanus on 4/23/20.
//  Copyright © 2020 Square, Inc. All rights reserved.
//

import Foundation

public struct LinkedComponent {
    public let type: String
    public let rootType: String
    public let providers: [StandardProvider]
    public let seed: String
    public let includedModules: [String]
    public let subcomponents: [String]
    public let isRoot: Bool
}

public struct LinkedModule {
    public let type: String
    public let providers: [StandardProvider]
    public let includedModules: [String]
    public let subcomponents: [String]
}

public struct ModuleInterface {
    public let components: [LinkedComponent]
    public let modules: [LinkedModule]
}

public struct Linker {
    static func linkProviders(files: [FileRepresentation]) -> ModuleInterface {
        let danglingProviders = files.flatMap { $0.components }.flatMap { $0.danglingProviders } + files.flatMap { $0.modules}.flatMap { $0.danglingProviders }
        let danglingProvidersByReference = danglingProviders.reduce(into: [String:DanglingProvider]()) { (dict, provider) in
            if let _ = dict[provider.reference] {
                print("Warning. Duplicate dangling provider reference: \(provider.reference)")
            }
            dict[provider.reference] = provider
        }
        
        let linkedComponents = files.flatMap { $0.components }.map { component -> LinkedComponent in
            let linkedProviders = link(
                referenceProviders: component.referenceProviders,
                danglingProvidersByReference: danglingProvidersByReference
            )
            let allProviders = component.providers + linkedProviders
            return LinkedComponent(
                type: component.type,
                rootType: component.rootType,
                providers: allProviders,
                seed: component.seed,
                includedModules: component.includedModules,
                subcomponents: component.subcomponents,
                isRoot: component.isRoot
            )
        }
        
        let linkedModules = files.flatMap { $0.modules }.map { (module) -> LinkedModule in
            let linkedProviders = link(
                referenceProviders: module.referenceProviders,
                danglingProvidersByReference: danglingProvidersByReference
            )
            let allProviders = module.providers + linkedProviders
            return LinkedModule(
                type: module.type,
                providers: allProviders,
                includedModules: module.includedModules,
                subcomponents: module.subcomponents
            )
        }
        
        return ModuleInterface(
            components: linkedComponents,
            modules: linkedModules
        )
    }
    
    private static func link(referenceProviders: [ReferenceProvider], danglingProvidersByReference: [String:DanglingProvider]) -> [StandardProvider] {
        return referenceProviders.compactMap { referenceProvider -> StandardProvider? in
            guard let linked = danglingProvidersByReference[referenceProvider.reference] else {
                print("Warning. Failed to find pointee for reference provider: \(referenceProvider)")
                return nil
            }
            return StandardProvider(
                type: referenceProvider.type,
                dependencies: linked.dependencies,
                tag: referenceProvider.tag,
                scoped: referenceProvider.scoped,
                collectionType: referenceProvider.collectionType
            )
        }
    }
}