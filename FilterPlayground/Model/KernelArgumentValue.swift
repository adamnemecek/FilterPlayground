//
//  KernelAttributeValue.swift
//  FilterPlayground
//
//  Created by Leo Thomas on 30.09.17.
//  Copyright © 2017 Leo Thomas. All rights reserved.
//

import CoreImage
import simd

enum KernelArgumentValue: Equatable {
    case float(Float)
    case vec2(Float, Float)
    case vec3(Float, Float, Float)
    case vec4(Float, Float, Float, Float)
    case sample(CIImage)
    case color(Float, Float, Float, Float)
    case uint2(UInt, UInt)

    var asKernelValue: Any {
        switch self {
        case let .float(value):
            return value
        case let .vec2(a, b):
            return CIVector(x: CGFloat(a), y: CGFloat(b))
        case let .vec3(a, b, c):
            return CIVector(x: CGFloat(a), y: CGFloat(b), z: CGFloat(c))
        case let .vec4(a, b, c, d):
            return CIVector(x: CGFloat(a), y: CGFloat(b), z: CGFloat(c), w: CGFloat(d))
        case let .color(a, b, c, d):
            return CIColor(red: CGFloat(a), green: CGFloat(b), blue: CGFloat(c), alpha: CGFloat(d))
        case let .sample(image):
            return CISampler(image: image)
        case .uint2:
            fatalError()
        }
    }

    func withUnsafeMetalBufferValue<T>(_ body: (UnsafeRawPointer, Int) -> T) -> T? {
        switch self {
        case var .float(value):
            return body(&value, MemoryLayout<Float>.size)
        case let .vec2(x, y):
            var value = float2(x, y)
            return body(&value, MemoryLayout<float2>.size)
        case let .vec3(x, y, z):
            var value = float3(x, y, z)
            return body(&value, MemoryLayout<float3>.size)
        case let .vec4(x, y, z, w):
            var value = float4(x, y, z, w)
            return body(&value, MemoryLayout<float4>.size)
        case .uint2:
            return nil
        case .color:
            return nil
        case .sample:
            return nil
        }
    }
}

extension KernelArgumentValue: Codable {
    private enum CodingKeys: String, CodingKey {
        case float
        case vec2
        case vec3
        case vec4
        case sample
        case color
        case uint2
    }

    private enum CodableErrors: Error {
        case unkownValue
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .float(value):
            try container.encode(value, forKey: .float)
            break
        case let .vec2(a, b):
            try container.encode([a, b], forKey: .vec2)
            break
        case let .vec3(a, b, c):
            try container.encode([a, b, c], forKey: .vec3)
            break
        case let .vec4(a, b, c, d):
            try container.encode([a, b, c, d], forKey: .vec4)
            break
        case let .color(a, b, c, d):
            try container.encode([a, b, c, d], forKey: .color)
            break
        case let .uint2(a, b):
            try container.encode([a, b], forKey: .uint2)
        case .sample:
            // we are not encoding images in the json
            break
        }
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? values.decode(Float.self, forKey: .float) {
            self = .float(value)
            return
        }
        if let value = try? values.decode([Float].self, forKey: .vec2) {
            guard value.count == 2 else {
                throw CodableErrors.unkownValue
            }
            self = .vec2(value[0], value[1])
            return
        }
        if let value = try? values.decode([Float].self, forKey: .vec3) {
            guard value.count == 3 else {
                throw CodableErrors.unkownValue
            }
            self = .vec3(value[0], value[1], value[2])
            return
        }
        if let value = try? values.decode([Float].self, forKey: .vec3) {
            guard value.count == 3 else {
                throw CodableErrors.unkownValue
            }
            self = .vec3(value[0], value[1], value[2])
            return
        }
        if let value = try? values.decode([Float].self, forKey: .vec4) {
            guard value.count == 4 else {
                throw CodableErrors.unkownValue
            }
            self = .vec4(value[0], value[1], value[2], value[3])
            return
        }
        if let value = try? values.decode([Float].self, forKey: .color) {
            guard value.count == 4 else {
                throw CodableErrors.unkownValue
            }
            self = .color(value[0], value[1], value[2], value[3])
            return
        }
        if let value = try? values.decode([UInt].self, forKey: .uint2) {
            guard value.count == 2 else {
                throw CodableErrors.unkownValue
            }
            self = .uint2(value[0], value[1])
            return
        }

        throw CodableErrors.unkownValue
    }
}
