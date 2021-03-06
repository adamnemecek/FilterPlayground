//
//  CoreImageKernel.swift
//  FilterPlayground
//
//  Created by Leo Thomas on 30.09.17.
//  Copyright © 2017 Leo Thomas. All rights reserved.
//

import MetalKit

class CoreImageKernel: NSObject, Kernel, MTKViewDelegate {
    var type: KernelType {
        return .coreimage
    }

    var extentSettings: KernelOutputSizeSetting {
        return .sizeAndPosition
    }

    var extent: CGRect {
        switch outputSize {
        case .inherit:
            return CGRect(origin: .zero, size: CGSize(width: 1000, height: 1000))
        case let .custom(value):
            return value
        }
    }

    var outputSize: KernelOutputSize = .inherit

    var inputImages: [CIImage] = []

    let commandQueue: MTLCommandQueue?
    let device: MTLDevice?
    var mtkView: FPMTKView!
    var context: CIContext?

    var outputView: KernelOutputView {
        return mtkView
    }

    var arguments: [KernelArgument] = []
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    required override init() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device?.makeCommandQueue()
        #if !(targetEnvironment(simulator))
            context = CIContext(mtlDevice: device!)
        #else
            context = CIContext()
        #endif
        super.init()
        mtkView = FPMTKView(device: device, delegate: self)
    }

    class var requiredArguments: [KernelArgumentType] {
        return []
    }

    var requiredInputImages: Int {
        return 0
    }

    class var supportedArguments: [KernelArgumentType] {
        return [.float, .vec2, .vec3, .vec4, .sample, .color]
    }

    static func initialSource(with name: String) -> String {
        return "kernel \(returnType) \(name)(\(initialArguments)) {\n\(initialSourceBody)\n}"
    }

    class var initialArguments: String {
        return ""
    }

    class var returnType: KernelArgumentType {
        return .vec4
    }

    class var initialSourceBody: String {
        return "\(Settings.spacingValue)return vec4(1.0, 1.0, 1.0, 1.0);"
    }

    var kernel: CIKernel?

    func render() {
        mtkView.setNeedsDisplay()
    }

    func getImage() -> CIImage? {
        return apply(with: inputImages, attributes: arguments.compactMap { $0.value })
    }

    func compile(source: String, completion: @escaping (KernelCompilerResult) -> Void) {
        let errorHelper = ErrorHelper()
        if compile(source: source) {
            completion(.success(warnings: []))
        } else if let errorString = errorHelper.errorString() {
            completion(.failed(errors: CoreImageErrorParser.compileErrors(for: errorString)))
        } else {
            completion(.failed(errors: [KernelError.compile(lineNumber: -1, characterIndex: -1, type: .error, message: "Unkown Error. Please check your code.", note: nil)]))
        }
    }

    func compile(source: String) -> Bool {
        if let kernel = CIKernel(source: source) {
            self.kernel = kernel
            return true
        }
        return false
    }

    func apply(with _: [CIImage], attributes: [KernelArgumentValue]) -> CIImage? {
        let arguments: [Any] = attributes.compactMap { $0.asKernelValue }

        return kernel?.apply(extent: extent, roiCallback: { (_, rect) -> CGRect in
            rect
        }, arguments: arguments)
    }

    // Mark: - MTKViewDelegate

    func draw(in view: MTKView) {
        guard let currentDrawable = view.currentDrawable,
            let output = apply(with: inputImages, attributes: arguments.compactMap { $0.value }) else { return }
        let commandBuffer = commandQueue?.makeCommandBuffer()
        view.drawableSize = output.extent.size
        #if !(targetEnvironment(simulator))
            context?.render(output,
                            to: currentDrawable.texture,
                            commandBuffer: commandBuffer,
                            bounds: output.extent,
                            colorSpace: colorSpace)
        #endif

        commandBuffer?.addCompletedHandler(mtkView.bufferCompletionHandler)
        commandBuffer?.present(currentDrawable)
        commandBuffer?.commit()
    }

    func mtkView(_: MTKView, drawableSizeWillChange _: CGSize) {
        mtkView.setNeedsDisplay()
    }
}
