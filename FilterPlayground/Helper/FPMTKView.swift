//
//  FPMTKView.swift
//  FilterPlayground
//
//  Created by Leo Thomas on 13.10.17.
//  Copyright © 2017 Leo Thomas. All rights reserved.
//

import MetalKit

class FPMTKView: MTKView, MTKViewDelegate {
    weak var externalDelegate: MTKViewDelegate?
    override var delegate: MTKViewDelegate? {
        set {
            externalDelegate = newValue
        }
        get {
            return self
        }
    }

    var customNeedsDisplay = false
    var timer: Timer?

    #if os(iOS)
        weak var statisticsView: StatisticsView?
    #endif

    convenience init(device: MTLDevice?, delegate: MTKViewDelegate) {
        self.init(frame: .zero, device: device)
        self.delegate = delegate
        enableSetNeedsDisplay = true
        if Settings.showStatistics {
            showStatistics()
        }
        #if os(iOS)
            if traitCollection.horizontalSizeClass != .compact {
                contentMode = .scaleAspectFit
                contentScaleFactor = UIScreen.main.scale
                let dragInteraction = UIDragInteraction(delegate: self)
                addInteraction(dragInteraction)
            }
        #endif
        autoResizeDrawable = false
        framebufferOnly = false
        super.delegate = self
    }

    private override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        NotificationCenter.default.addObserver(self, selector: #selector(frameRateChanged), name: FrameRateManager.frameRateChangedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showStatisticsSettingChanged), name: Settings.showStatisticsChangedNotificationName, object: nil)
        activateTimer()
    }

    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if os(iOS) || os(tvOS)
        override func setNeedsDisplay() {
            #if (targetEnvironment(simulator))
                backgroundColor = .randomColor
            #endif
            customNeedsDisplay = true
        }
    #endif

    func activateTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: FrameRateManager.shared.frameInterval, repeats: true, block: didUpdate)
        timer?.fire()
    }

    func deactivateTimer() {
        timer?.invalidate()
    }

    func didUpdate(timer _: Timer) {
        guard customNeedsDisplay else { return }
        customNeedsDisplay = false
        super.setNeedsDisplay()
    }

    @objc func frameRateChanged() {
        deactivateTimer()
        activateTimer()
    }

    func showStatistics() {
        #if os(iOS) || os(tvOS)
            // TODO: hide statistics if the view is inside a PIP window
            guard statisticsView == nil else { return }
            let newStatisticsView = StatisticsView(frame: CGRect(x: 0, y: bounds.height - 44, width: bounds.width, height: 44))
            newStatisticsView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
            addSubview(newStatisticsView)
            statisticsView = newStatisticsView
        #endif
    }

    @objc func showStatisticsSettingChanged() {
        if Settings.showStatistics {
            showStatistics()
        } else {
            #if os(iOS) || os(tvOS)
                statisticsView?.removeFromSuperview()
            #else
                print("implement statistics view for mac")
            #endif
        }
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange _: CGSize) {
        externalDelegate?.mtkView(view, drawableSizeWillChange: drawableSize)
    }

    let numberOfSkippedFrames = 10
    // we skip frames an average because updating the label with 60 or 120 hz is too fast

    var totalExecutionTimes: [Double] = [Double](repeating: 0, count: 10)
    var gpuExecutionTimes: [Double] = [Double](repeating: 0, count: 10)
    var framesCount = 0
    var totalStartTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    var gpuStartTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    override var intrinsicContentSize: CGSize {
        return drawableSize
    }

    func draw(in view: MTKView) {
        externalDelegate?.draw(in: view)
        gpuStartTime = CFAbsoluteTimeGetCurrent()
    }

    func bufferCompletionHandler(buffer _: MTLCommandBuffer) {
        guard framesCount == numberOfSkippedFrames else {
            framesCount += 1
            return
        }

        #if os(iOS) || os(tvOS)
            statisticsView?.updateStatistics(frameRate: Double(numberOfSkippedFrames) / totalExecutionTimes.average(), time: gpuExecutionTimes.average())
        #endif
        let time = CFAbsoluteTimeGetCurrent()
        totalExecutionTimes.removeFirst()
        totalExecutionTimes.append(time - totalStartTime)
        totalStartTime = time
        gpuExecutionTimes.removeFirst()
        gpuExecutionTimes.append(time - gpuStartTime)
        // TODO: find way for more precise gpu execution time
        framesCount = 0
    }
}

#if os(iOS)
    extension FPMTKView: UIDragInteractionDelegate {

        // MARK: UIDragInteractionDelegate

        func dragInteraction(_: UIDragInteraction, itemsForBeginning _: UIDragSession) -> [UIDragItem] {
            #if !(targetEnvironment(simulator))
                guard let texture = self.currentDrawable?.texture,
                    let image = UIImage(texture: texture) else { return [] }
                let imageItemProvider = NSItemProvider(object: image)
                let dragItem = UIDragItem(itemProvider: imageItemProvider)
                dragItem.previewProvider = {
                    UIDragPreview(view: DragInteractionImageView(image: image))
                }
                return [dragItem]
            #else
                return []
            #endif
        }
    }
#endif
