//
//  ApplicationLayoutViewController.swift
//  FilterPlayground
//
//  Created by Leo Thomas on 09.04.18.
//  Copyright © 2018 Leo Thomas. All rights reserved.
//

import UIKit

class ApplicationLayoutViewController: UIViewController {
    let subNavigationController = UINavigationController(nibName: nil, bundle: nil)

    let outerStackView = UIStackView(frame: .zero)

    let sourceEditorController = UIStoryboard.main.instantiate(viewController: SourceEditorViewController.self)
    let attributesViewController = UIStoryboard.main.instantiate(viewController: AttributesViewController.self)
    let liveViewController = UIStoryboard.main.instantiate(viewController: LiveViewController.self)

    let innerLayoutController = ApplicationInnerLayoutViewController(nibName: nil, bundle: nil)

    init() {
        super.init(nibName: nil, bundle: nil)
        keyboardObserver = KeyboardObserver(callback: keyboardChanged)
        keyboardObserver.startObserving()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var keyboardObserver: KeyboardObserver!
    let mainController = MainController()

    var isMinified: Bool {
        if traitCollection.userInterfaceIdiom == .phone {
            return true
        }
        return traitCollection.horizontalSizeClass == .compact
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureMainController()

        innerLayoutController.addChildViewController(sourceEditorController)
        subNavigationController.viewControllers = [innerLayoutController]

        outerStackView.frame = view.bounds
        outerStackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        outerStackView.addArrangedSubview(subNavigationController.view)
        outerStackView.distribution = .fillEqually

        if UIDevice.current.userInterfaceIdiom == .phone {
            outerStackView.addArrangedSubview(liveViewController.view)
        } else {
            addChildViewController(liveViewController)
            innerLayoutController.stackView.addArrangedSubview(liveViewController.view)
            innerLayoutController.addChildViewController(attributesViewController)
            innerLayoutController.stackView.addSubview(attributesViewController.view)
        }
        view.addSubview(outerStackView)
        innerLayoutController.stackView.addArrangedSubview(sourceEditorController.view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentDocumentPickerIfNeeded()
    }

    func configureMainController() {
        mainController.liveViewController = liveViewController
        mainController.attributesViewController = attributesViewController
        mainController.sourceEditorViewController = sourceEditorController
    }

    func configureNavigationController() {
        var rightItems: [UIBarButtonItem] = []

        let attributesBarbuttonItem = UIBarButtonItem(title: "Attributes", style: .plain, target: self, action: #selector(attributesButtonTapped))

        let runBarbuttonItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(runButtonTapped))
        rightItems.append(contentsOf: [runBarbuttonItem, attributesBarbuttonItem])

        if traitCollection.userInterfaceIdiom == .phone && keyboardObserver.isKeyboardVisible {
            let dismissKeyboardBarbuttonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "DismissKeyboard"), style: .plain, target: self, action: #selector(dismissKeyboardButtonTapped))
            rightItems.append(dismissKeyboardBarbuttonItem)
        }
        innerLayoutController.navigationItem.setRightBarButtonItems(rightItems, animated: false)

        var leftItems: [UIBarButtonItem] = []
        let documentsBarbuttonItem = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(documentsButtonTapped(sender:)))
        let settingsBarbuttonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(settingsButtonTapped(sender:)))
        let exportBarbuttonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(exportButtonTapped(sender:)))
        leftItems.append(contentsOf: [documentsBarbuttonItem, settingsBarbuttonItem, exportBarbuttonItem])
        innerLayoutController.navigationItem.setLeftBarButtonItems(leftItems, animated: false)
    }

    func presentDocumentPickerIfNeeded() {
        if mainController.project == nil {
            let documentBrowser = UIStoryboard.main.instantiate(viewController: DocumentBrowserViewController.self)
            documentBrowser.didOpenedDocument = { document in
                self.presentedViewController?.dismiss(animated: true, completion: nil)
                self.mainController.didOpened(document: document)
            }
            documentBrowser.modalPresentationStyle = .formSheet
            present(documentBrowser, animated: true, completion: nil)
        }
    }

    @objc func attributesButtonTapped() {
        if isMinified {
            innerLayoutController.navigationController?.pushViewController(attributesViewController, animated: true)
        } else {
            if attributesViewController.view.superview == nil {
                attributesViewController.view.isHidden = true
                innerLayoutController.addChildViewController(attributesViewController)
                innerLayoutController.stackView.addArrangedSubview(attributesViewController.view)
                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: [], animations: {
                    self.attributesViewController.view.isHidden = false
                    self.innerLayoutController.stackView.layoutIfNeeded()
                }, completion: nil)

            } else {
                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: [], animations: {
                    self.attributesViewController.view.isHidden = true
                    self.attributesViewController.view.superview?.layoutIfNeeded()

                }) { _ in
                    self.attributesViewController.view.isHidden = false
                    self.attributesViewController.removeFromParentViewController()
                    self.attributesViewController.view.removeFromSuperview()
                }
            }
        }
    }

    @objc func runButtonTapped() {
        mainController.run()
    }

    @objc func dismissKeyboardButtonTapped() {
        sourceEditorController.textView.textView.resignFirstResponder()
    }

    @objc func settingsButtonTapped(sender: UIBarButtonItem) {
        let settings = UIStoryboard.main.instantiate(viewController: SettingsTableViewController.self)
        settings.modalPresentationStyle = .popover
        settings.popoverPresentationController?.barButtonItem = sender

        present(settings, animated: true, completion: nil)
    }

    @objc func documentsButtonTapped(sender: UIBarButtonItem) {
        let documents = UIStoryboard.main.instantiate(viewController: DocumentBrowserViewController.self)
        documents.modalPresentationStyle = .popover
        documents.popoverPresentationController?.barButtonItem = sender
        documents.didOpenedDocument = mainController.didOpened

        present(documents, animated: true, completion: nil)
    }

    @objc func exportButtonTapped(sender: UIBarButtonItem) {
        guard let project = mainController.project else { return }
        let export = ExportOptionsViewController(project: project, showCompileWarning: sourceEditorController.errors.count != 0)
        export.modalPresentationStyle = .popover
        export.popoverPresentationController?.barButtonItem = sender
        present(export, animated: true, completion: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceIdiom == .pad {
            liveViewController.view.removeFromSuperview()
            if traitCollection.horizontalSizeClass == .compact {
                attributesViewController.removeFromParentViewController()
                attributesViewController.view.removeFromSuperview()
                addChildViewController(liveViewController)
                outerStackView.addArrangedSubview(liveViewController.view)
                outerStackView.axis = .vertical
            } else {
                innerLayoutController.addChildViewController(liveViewController)
                innerLayoutController.stackView.addArrangedSubview(liveViewController.view)
                innerLayoutController.addChildViewController(attributesViewController)
                innerLayoutController.stackView.addArrangedSubview(attributesViewController.view)
            }
        } else if previousTraitCollection?.userInterfaceIdiom == .phone {
            outerStackView.axis = UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight ? .horizontal : .vertical
        }
    }

    override func willTransition(to _: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: traitCollection, with: coordinator)
    }

    func keyboardChanged(with _: KeyboardEvent, object _: KeyboardNotificationObject) {
        configureNavigationController()
    }
}
