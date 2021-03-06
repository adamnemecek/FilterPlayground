//
//  KernelAttributeType.swift
//  FilterPlayground
//
//  Created by Leo Thomas on 30.09.17.
//  Copyright © 2017 Leo Thomas. All rights reserved.
//

import CoreImage
#if os(iOS) || os(tvOS)
    import UIKit
#endif

enum KernelArgumentType: String, Codable, Equatable {
    case float
    case vec2
    case vec3
    case vec4
    case sample = "__sample"
    case color = "__color"
    case void
    case uint2
    case texture2d

    static var all: [KernelArgumentType] {
        return [.float, .vec2, .vec3, .vec4, .sample, .color, .void, uint2, texture2d]
    }
}

extension KernelArgumentType {
    var defaultValue: KernelArgumentValue {
        switch self {
        case .float:
            return .float(0)
        case .vec2:
            return .vec2(0, 0)
        case .vec3:
            return .vec3(0, 0, 0)
        case .vec4:
            return .vec4(0, 0, 0, 0)
        case .color:
            return .color(0, 0, 0, 0)
        case .uint2:
            return .uint2(0, 0)
        case .void:
            fatalError()
        case .sample,
             .texture2d:
            #if os(iOS) || os(tvOS)
                return .sample(#imageLiteral(resourceName: "DefaultImage").asCIImage!)
            #else
                return .sample(CIImage(color: .black))
            #endif
        }
    }

    var availableDataBindings: [DataBinding] {
        switch self {
        case .float:
            return [.time]
        case .vec2:
            return [.touch]
        case .vec3:
            return []
        case .vec4:
            return []
        case .color:
            return []
        case .sample,
             .texture2d:
            return [.camera]
        case .uint2:
            return []
        case .void:
            return []
        }
    }

    var supportsDataBinding: Bool {
        return availableDataBindings.count > 0
    }
}
