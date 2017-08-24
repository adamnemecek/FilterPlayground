//
//  KernelAttributeTableViewCell.swift
//  FilterPlayground
//
//  Created by Leo Thomas on 29.07.17.
//  Copyright © 2017 Leo Thomas. All rights reserved.
//

import UIKit

class KernelAttributeTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var valueSelectionView: UIView!
    
    var valueButton: UIView!
    
    var attribute: KernelAttribute? {
        didSet {
            if let type = attribute?.type {
                if let oldType = oldValue?.type,
                    oldType == type {
                    return
                }
                nameTextField.text = attribute?.name
                setupValueView(for: type, value: attribute?.value)
                typeButton.setTitle(type.rawValue, for: .normal)
            } else {
                typeButton.setTitle("type", for: .normal)
                valueSelectionView.subviews.forEach{ $0.removeFromSuperview() }
                nameTextField.text = nil
            }
        }
    }

    var updateCallBack: ((UITableViewCell, KernelAttribute) -> ())?

    @IBAction func nameTextFieldChanged(_ sender: Any) {
        guard let name = nameTextField.text else {
            return
        }
        attribute?.name = name
        update()
    }
    
    
    func update() {
        guard let attribute = attribute else {
            return
        }
  
        updateCallBack?(self, attribute)
    }
    
    @IBAction func selectType(_ sender: UIButton) {

        let viewController = UIStoryboard(name: "ValuePicker", bundle: nil).instantiateViewController(withIdentifier: "selectTypeViewControllerIdentifier") as! SelectTypeViewController
        
        viewController.modalPresentationStyle = .popover
        viewController.popoverPresentationController?.sourceView = sender
        viewController.popoverPresentationController?.sourceRect = sender.bounds
        viewController.didSelectType = { type in
            self.attribute = KernelAttribute(name: self.attribute?.name ?? "", type: type, value: type.defaultValue)
            self.setupValueView(for: type, value: self.attribute!.value)
            self.update()
        }
        UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.present(viewController, animated: true, completion: nil)
    }
    
    @objc func valueButtonTapped(sender: UIButton) {
        let viewController = UIStoryboard(name: "ValuePicker", bundle: nil).instantiateViewController(withIdentifier: "SelectFloatViewControllerIdentifier") as! FloatPickerViewController
        self.valueButton = sender
        viewController.valueChanged = { value in
            self.attribute?.value = .float(Float(value))
            (self.valueButton as? UIButton)?.setTitle("\(value)", for: .normal)
            self.updateCallBack?(self, self.attribute!)
        }
        
        viewController.modalPresentationStyle = .popover
        viewController.popoverPresentationController?.sourceView = valueSelectionView
        viewController.popoverPresentationController?.sourceRect = valueSelectionView.bounds
        
        UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.present(viewController, animated: true, completion: nil)
    }
    
    @objc func colorButtonTapped(sender: UIButton) {
        let viewController = UIStoryboard(name: "ValuePicker", bundle: nil).instantiateViewController(withIdentifier: "ColorPickerViewControllerIdentifier") as! ColorPickerViewController
        viewController.colorChanged = { r, g ,b , a in
            self.attribute?.value = .color(r,g,b,a)
            self.valueButton.backgroundColor = UIColor(displayP3Red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
            self.updateCallBack?(self, self.attribute!)
        }
        
        viewController.modalPresentationStyle = .popover
        viewController.popoverPresentationController?.sourceView = valueSelectionView
        viewController.popoverPresentationController?.sourceRect = valueSelectionView.bounds
        
        UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.present(viewController, animated: true, completion: nil)
    }
    
    func setupValueView(for type: KernelAttributeType, value: KernelAttributeValue?) {
        valueSelectionView.subviews.forEach{ $0.removeFromSuperview() }
        switch (type, attribute?.value) {
        case (.sample, .sample(let image)?) :
            let imageView = CustomImageView(frame: valueSelectionView.bounds)
            imageView.didSelectImage = { image in
                self.attribute?.value = .sample(image.image!)
                self.updateCallBack?(self, self.attribute!)
            }
            imageView.image = image
            imageView.backgroundColor = .gray
            valueSelectionView.addSubview(imageView)
            break
        case (.color, .color(let r, let g , let b , let a)?):
            let button = UIButton(frame: valueSelectionView.bounds)
            valueSelectionView.addSubview(button)
            button.backgroundColor = UIColor(displayP3Red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
            button.addTarget(self, action: #selector(colorButtonTapped(sender:)), for: .touchUpInside)
            valueButton = button
            break
        case (.vec2, .vec2(let a, let b)?):
            let picker = VectorValuePicker(frame: valueSelectionView.bounds, values: [a, b])
            picker.valuesChanged = { values in
                self.attribute?.value = .vec2(values[0], values[1])
                self.updateCallBack?(self, self.attribute!)
            }
            valueButton = picker
            valueSelectionView.addSubview(picker)
        case (.vec3, .vec3(let a, let b, let c)?):
            let picker = VectorValuePicker(frame: valueSelectionView.bounds, values: [a, b, c])
            picker.valuesChanged = { values in
                self.attribute?.value = .vec3(values[0], values[1], values[2])
                self.updateCallBack?(self, self.attribute!)
            }
            valueButton = picker
            valueSelectionView.addSubview(picker)
        case (.vec4, .vec4(let a, let b, let c, let d)?):
            let picker = VectorValuePicker(frame: valueSelectionView.bounds, values: [a, b, c, d])
            picker.valuesChanged = { values in
                self.attribute?.value = .vec4(values[0], values[1], values[2], values[3])
                self.updateCallBack?(self, self.attribute!)
            }
            valueButton = picker
            valueSelectionView.addSubview(picker)
        case (.float, .float(let floatValue)?):
            let button = UIButton(frame: valueSelectionView.bounds)
            valueSelectionView.addSubview(button)
            button.addTarget(self, action: #selector(valueButtonTapped(sender:)), for: .touchUpInside)
            button.setTitleColor(.blue, for: .normal)
            button.setTitle("\(floatValue)", for: .normal)
            valueButton = button
            break
        default:
            
            break
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        attribute = nil
    }
    
}
