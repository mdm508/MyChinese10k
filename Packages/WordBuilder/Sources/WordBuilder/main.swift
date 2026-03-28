//
//  main.swift
//  StoreBuilderMain
//
//  Created by m on 7/12/23.


import Foundation
import CoreDataModels
import CoreData


print("🚀 STORE BUILDER STARTING...")
// REGISTER THE TRANSFORMER FIRST
StringArrayTransformer.register()

let context = createFreshContext()
seedDatabase(using: context)
finalizeAndExport(from: context)

print("🏁 PROCESS COMPLETE.")


