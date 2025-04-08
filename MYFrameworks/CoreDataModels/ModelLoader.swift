//
//  ModelLoader.swift
//  CoreDataModels
//
//  Created by Matthew McLaughlin on 3/17/25.
//
import CoreData

// A helper class to locate the framework bundle
private class BundleFinder {}

public enum ModelLoader {
    public static let name = Constants.STORE_NAME
    // Retrieve the framework bundle using the helper class
    private static var bundle: Bundle {
        return Bundle(for: BundleFinder.self)
    }
    public static func loadModel() -> NSManagedObjectModel {
        guard let url = bundle.url(forResource: Self.name, withExtension: "mom") else {
            fatalError("Could not find model: \(Self.name)")
        }
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Could not load model at \(url)")
        }
        return model
    }
}
