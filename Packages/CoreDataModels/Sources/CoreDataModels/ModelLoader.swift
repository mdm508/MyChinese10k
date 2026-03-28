//
//  ModelLoader.swift
//  CoreDataModels
//
//  Created by Matthew McLaughlin on 3/17/25.
//
import CoreData

public enum ModelLoader {
    public static let name = Constants.STORE_NAME
    public static func loadModel() -> NSManagedObjectModel {
        guard let url = Bundle.module.url(forResource: Self.name, withExtension: "mom") else {
            fatalError("Could not find model: \(Self.name)")
        }
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Could not load model at \(url)")
        }
        // --- PRINT THE LOCATION HERE ---
                print("📂 Managed Object Model Location:")
                print(url.path)
        return model
    }
}
