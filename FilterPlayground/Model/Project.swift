//
//  Document.swift
//  FilterPlayground
//
//  Created by Leo Thomas on 01.08.17.
//  Copyright © 2017 Leo Thomas. All rights reserved.
//

import UIKit

enum ProjectError: Error {
    case unknownFileFormat
    case encodeError
}

class Project: UIDocument {
    static let type: String = "FilterPlayground"

    var resourcesWrapper = FileWrapper(directoryWithFileWrappers: [:])

    var metaData: ProjectMetaData = ProjectMetaData(arguments: [], type: .coreimagewarp, inputImages: [])
    var source: String = "" {
        didSet {
            self.updateChangeCount(.done)
        }
    }

    var title: String {
        return fileURL.lastPathComponent
    }

    convenience init(fileURL url: URL, type: KernelType) {
        self.init(fileURL: url)
        metaData.type = type
        source = metaData.initialSource()
        metaData.arguments = metaData.initalArguments()
        metaData.inputImages = metaData.initialInputImages()
    }

    override func contents(forType _: String) throws -> Any {
        let meta = try JSONEncoder().encode(metaData)

        guard let sourceData = source.data(using: .utf8) else {
            throw ProjectError.encodeError
        }

        let fileWrapper = FileWrapper(directoryWithFileWrappers: [:])
        fileWrapper.addRegularFile(withContents: meta, preferredFilename: "metadata.json")
        fileWrapper.addRegularFile(withContents: sourceData, preferredFilename: "source.\(metaData.type.shadingLanguage.fileExtension)")

        if metaData.inputImages.count > 0 {
            let inputImagesFileWrapper = FileWrapper(directoryWithFileWrappers: [:])
            for imageValue in metaData.inputImages {
                guard let image = imageValue.image else { continue }
                inputImagesFileWrapper.addRegularFile(withContents: UIImageJPEGRepresentation(image, 1.0)!, preferredFilename: "\(imageValue.index).jpg")
            }

            inputImagesFileWrapper.preferredFilename = "inputimages"
            fileWrapper.addFileWrapper(inputImagesFileWrapper)
        }

        resourcesWrapper = FileWrapper(directoryWithFileWrappers: [:])
        metaData.arguments.forEach { argument in
            guard case let .sample(image) = argument.value else { return }
            self.addImage(image: image, for: argument.name)
        }

        resourcesWrapper.preferredFilename = "Resources"
        fileWrapper.addFileWrapper(resourcesWrapper)

        return fileWrapper
    }

    func addImage(image: CIImage, for name: String) {
        guard let data = image.asJPGData else { return }
        addResource(for: "\(name).jpg", with: data)
    }

    func getImage(for name: String) -> CIImage? {
        guard let child = resourcesWrapper.fileWrappers?["\(name).jpg"],
            let data = child.regularFileContents else { return nil }
        return CIImage(data: data)
    }

    func renameImage(for name: String, with newName: String) {
        renameResouce(for: "\(name).jpg", with: "\(newName).jpg")
    }

    func addResource(for name: String, with data: Data) {
        resourcesWrapper.addRegularFile(withContents: data, preferredFilename: name)
    }

    func getAllResources() -> [(name: String, data: Data)] {
        return resourcesWrapper.fileWrappers?.values.compactMap {
            guard let data = $0.regularFileContents,
                let name = $0.preferredFilename else { return nil }
            return (name: name, data: data)
        } ?? []
    }

    func removeResource(for name: String) {
        guard let child = resourcesWrapper.fileWrappers?[name] else { return }
        resourcesWrapper.removeFileWrapper(child)
    }

    func renameResouce(for name: String, with newName: String) {
        guard let child = resourcesWrapper.fileWrappers?[name],
            let data = child.regularFileContents else { return }
        removeResource(for: name)
        addResource(for: newName, with: data)
    }

    override func load(fromContents contents: Any, ofType _: String?) throws {
        guard let filewrapper = contents as? FileWrapper else {
            throw ProjectError.unknownFileFormat
        }

        guard let metaFilewrapper = filewrapper.fileWrappers?["metadata.json"] else {
            throw ProjectError.unknownFileFormat
        }

        guard let meta = metaFilewrapper.regularFileContents else {
            throw ProjectError.unknownFileFormat
        }

        metaData = try JSONDecoder().decode(ProjectMetaData.self, from: meta)
        guard let contentFilewrapper = filewrapper.fileWrappers?["source.\(metaData.type.shadingLanguage.fileExtension)"] else {
            throw ProjectError.unknownFileFormat
        }

        guard let contentsData = contentFilewrapper.regularFileContents else {
            throw ProjectError.unknownFileFormat
        }

        guard let sourceString = String(data: contentsData, encoding: .utf8) else {
            throw ProjectError.unknownFileFormat
        }

        if let resourcesFilewrapper = filewrapper.fileWrappers?["Resources"] {
            resourcesWrapper = resourcesFilewrapper
        }

        metaData.arguments = metaData.arguments.compactMap { argument in
            guard case .sample = argument.type else { return argument }
            return KernelArgument(index: argument.index, name: argument.name, type: argument.type, value: .sample(self.getImage(for: argument.name)!), access: argument.access, origin: argument.origin)
        }

        if let inputImagesFileWrapper = filewrapper.fileWrappers?["inputimages"] {
            var index = 0
            while index < metaData.type.kernelClass.init().requiredInputImages {
                if let data = inputImagesFileWrapper.fileWrappers?["\(index).jpg"]?.regularFileContents,
                    let image = UIImage(data: data) {
                    metaData.inputImages.append(KernelInputImage(image: image, index: index, shouldHighlightIfMissing: false))
                } else {
                    metaData.inputImages.append(KernelInputImage(image: nil, index: index, shouldHighlightIfMissing: false))
                }
                index += 1
            }
        }

        source = sourceString
    }

    override func save(to url: URL, for saveOperation: UIDocumentSaveOperation, completionHandler: ((Bool) -> Void)? = nil) {
        super.save(to: url, for: saveOperation, completionHandler: completionHandler)
    }
}
