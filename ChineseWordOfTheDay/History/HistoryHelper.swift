import SwiftUI
import CoreData
import Combine
import CoreDataModels

class HistoryHelper: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    internal let context: NSManagedObjectContext
    private var frc: NSFetchedResultsController<WordStatus>!
    
    @Published var sections: [NSFetchedResultsSectionInfo] = []
    @Published var selectedMonths: Set<String> = []
    @Published var allAvailableMonths: [String] = []
    @Published var currentSort: SortMode = .recent
    
    // 🎯 THE MASTER LEDGER
    @Published var flipStates: [NSManagedObjectID: Bool] = [:]
    
    enum FlipMode { case front, back, random }
    enum SortMode { case recent, indexAsc, indexDesc }

    // MARK: - Filter Status
    var isFiltered: Bool {
        currentSort != .recent || !selectedMonths.isEmpty
    }

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        setupFRC()
        updateAvailableMonths()
        syncLedger()
    }

    // MARK: - 🔄 The Shapeshifter Logic
    
    private func setupFRC() {
        let request: NSFetchRequest<WordStatus> = WordStatus.fetchRequest()
        
        let descriptors: [NSSortDescriptor]
        let sectionKey: String?
        
        switch currentSort {
        case .recent:
            descriptors = [
                NSSortDescriptor(key: "sectionIdentifier", ascending: false),
                NSSortDescriptor(key: "lastModified", ascending: false)
            ]
            sectionKey = "sectionIdentifier"
            
        case .indexAsc:
            descriptors = [NSSortDescriptor(key: "index", ascending: true)]
            sectionKey = nil
            
        case .indexDesc:
            descriptors = [NSSortDescriptor(key: "index", ascending: false)]
            sectionKey = nil
        }
        
        request.sortDescriptors = descriptors
        request.fetchBatchSize = 60
        
        if !selectedMonths.isEmpty {
            request.predicate = NSPredicate(format: "sectionIdentifier IN %@", selectedMonths)
        }
        
        frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: sectionKey,
            cacheName: nil
        )
        frc.delegate = self
        
        do {
            try frc.performFetch()
            self.sections = frc.sections ?? []
            self.syncLedger()
        } catch {
            print("❌ FRC Fetch Failed: \(error)")
        }
    }

    func updateSort(_ newSort: SortMode) {
        withAnimation(.easeInOut) {
            self.currentSort = newSort
            setupFRC()
        }
    }

    func resetToDefaults() {
        withAnimation(.spring()) {
            self.currentSort = .recent
            self.selectedMonths.removeAll()
            setupFRC()
        }
    }

    // MARK: -  delegado
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.sections = self.frc.sections ?? []
            self.updateAvailableMonths() // 🔄 Keep filter chips updated
            self.syncLedger()
        }
    }

    // MARK: - 🛠️ Ledger & Bulk Logic
    
    func syncLedger() {
        let allObjects = frc.fetchedObjects ?? []
        var hasNewItems = false
        
        for object in allObjects {
            if flipStates[object.objectID] == nil {
                flipStates[object.objectID] = false
                hasNewItems = true
            }
        }
        
        // Only trigger UI update if we actually added something
        if hasNewItems {
            self.objectWillChange.send()
        }
    }

    func toggleFlip(for id: NSManagedObjectID) {
        flipStates[id]?.toggle()
    }

    func bulkFlip(_ mode: FlipMode) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            var newStates = flipStates
            let currentlyVisibleIDs = frc.fetchedObjects?.map { $0.objectID } ?? []
            
            for id in currentlyVisibleIDs {
                switch mode {
                case .front:  newStates[id] = false
                case .back:   newStates[id] = true
                case .random: newStates[id] = Bool.random()
                }
            }
            self.flipStates = newStates
        }
    }

    // MARK: - Filtering
    
    func applyFilters() {
        setupFRC()
    }

    func toggleMonthFilter(_ month: String) {
        if selectedMonths.contains(month) {
            selectedMonths.remove(month)
        } else {
            selectedMonths.insert(month)
        }
        applyFilters()
    }

    private func updateAvailableMonths() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "WordStatus")
        request.resultType = .dictionaryResultType
        request.returnsDistinctResults = true
        request.propertiesToFetch = ["sectionIdentifier"]
        
        let results = try? context.fetch(request) as? [[String: String]]
        let newMonths = results?.compactMap { $0["sectionIdentifier"] }.sorted(by: >) ?? []
        
        if self.allAvailableMonths != newMonths {
            self.allAvailableMonths = newMonths
        }
    }

    // MARK: - Date Helpers
    
    func formatFullMonth(_ id: String) -> String {
        if id.isEmpty || currentSort != .recent { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: id) else { return id }
        let out = DateFormatter()
        out.dateFormat = "MMMM yyyy"
        return out.string(from: date).uppercased()
    }

    func formatShortMonth(_ id: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: id) else { return id }
        let out = DateFormatter()
        out.dateFormat = "MMM"
        return out.string(from: date).uppercased()
    }
}
