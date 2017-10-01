//
//  MetalKernelTests.swift
//  FilterPlaygroundMacTests
//
//  Created by Leo Thomas on 30.09.17.
//  Copyright © 2017 Leo Thomas. All rights reserved.
//

import XCTest
@testable import FilterPlaygroundMac

class MetalKernelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCompileError() {
        let source = """
        kernel vec2 untitled() {
            
        }
        """
        let result = MetalKernel.compile(source: source)
        switch result {
        case let .failed(errors):
            let expectedFirstError = KernelError.compile(lineNumber: 1, characterIndex: 8, type: .error, message: "unknown type name \'vec2\'", note: nil)
            let expectedSecondError = KernelError.compile(lineNumber: 1, characterIndex: 13, type: .error, message: "kernel must have void return type", note: nil)

            XCTAssertEqual(errors.first!, expectedFirstError)
            XCTAssertEqual(errors.last!, expectedSecondError)
            XCTAssertEqual(errors.count, 2)
            break
        default:
            XCTFail()
        }
    }

    func testCompilerMetalKernelWarnings() {
        let source = """
                #include <metal_stdlib>
                using namespace metal;
                
                kernel void untitled(
                texture2d<float, access::read> inTexture [[texture(0)]],
                texture2d<float, access::write> outTexture [[texture(1)]],
                uint2 gid [[thread_position_in_grid]])
                
                {
                    float a;
                
                }
        """
        let result = MetalKernel.compile(source: source)
        switch result {
        case let .success(kernel: kernel, errors: errors):
            let expectedFirstError = KernelError.compile(lineNumber: 10, characterIndex: 19, type: .warning, message: "unused variable 'a'", note: nil)

            XCTAssertEqual(errors.first!, expectedFirstError)
            XCTAssertEqual(errors.count, 1)
            XCTAssertNotNil((kernel as? MetalKernel)?.library)
            break
        default:
            XCTFail()
        }
    }

    func testCompileMetalKernel() {
        let source = MetalKernel.initialSource(with: "untitled")
        let result = MetalKernel.compile(source: source)
        switch result {
        case .success(kernel: _):
            break
        default:
            XCTFail()
        }
    }
}
