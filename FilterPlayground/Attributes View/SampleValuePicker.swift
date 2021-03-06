//
//  SampleValuePicker.swift
//  FilterPlayground
//
//  Created by Leo Thomas on 29.10.17.
//  Copyright © 2017 Leo Thomas. All rights reserved.
//

import UIKit

class SampleValuePicker: UIView, KernelArgumentValueView {
    var prefferedHeight: CGFloat {
        // TODO: use AVMakeRect(aspectRatio
        if let imageSize = imageView.image?.size {
            let ratio = bounds.width / imageSize.width
            return imageSize.height * ratio
        } else {
            return 0
        }
    }

    var prefferedUIAxis: UILayoutConstraintAxis {
        return .vertical
    }

    var updatedValueCallback: ((KernelArgumentValue) -> Void)?
    var value: KernelArgumentValue {
        didSet {
            if case let .sample(i) = value {
                imageView.image = i.asImage
            }
        }
    }

    weak var imageView: CustomImageView!

    required init?(frame: CGRect, value: KernelArgumentValue) {
        self.value = value
        super.init(frame: frame)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        var image: UIImage?
        if case let .sample(i) = value {
            image = i.asImage
        }
        let imageView = CustomImageView(image: image)
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit
        imageView.didSelectImage = { [weak self] customimageView in
            self?.updated(imageView: customimageView)
        }
        addSubview(imageView)
        self.imageView = imageView
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updated(imageView: CustomImageView) {
        guard let newImage = imageView.image?.asCIImage else { return }
        value = .sample(newImage)
        updatedValueCallback?(value)
    }
}
