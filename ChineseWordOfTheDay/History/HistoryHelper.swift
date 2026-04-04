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
    
    // 🎯 THE MASTER LEDGER
    // Maps each WordStatus ID to its current flipped state
    @Published var flipStates: [NSManagedObjectID: Bool] = [:]
    
    enum FlipMode { case front, back, random }
    enum SortMode { case recent, indexAsc, indexDesc }

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        setupFRC()
        updateAvailableMonths()
        syncLedger() // Initial sync
    }

    private func setupFRC() {
        let request: NSFetchRequest<WordStatus> = WordStatus.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "sectionIdentifier", ascending: false),
            NSSortDescriptor(key: "lastModified", ascending: false)
        ]
        request.fetchBatchSize = 60
        
        frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: "sectionIdentifier",
            cacheName: nil
        )
        frc.delegate = self
        
        try? frc.performFetch()
        self.sections = frc.sections ?? []
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.sections = self.frc.sections ?? []
            self.syncLedger() // 🔄 Keep the ledger in sync when data changes
        }
    }

    // MARK: - 🛠️ Ledger Logic
    
    /// Ensures every fetched object has an entry in our dictionary
    func syncLedger() {
        let allObjects = frc.fetchedObjects ?? []
        for object in allObjects {
            if flipStates[object.objectID] == nil {
                flipStates[object.objectID] = false // Default to front
            }
        }
    }

    /// Toggles a specific card - only notifies that specific card's listener
    func toggleFlip(for id: NSManagedObjectID) {
        flipStates[id]?.toggle()
    }

    /// ⚡️ THE BULK OPERATION
    func bulkFlip(_ mode: FlipMode) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            // Copy dictionary, modify, then push back once for performance
            var newStates = flipStates
            for id in newStates.keys {
                switch mode {
                case .front:  newStates[id] = false
                case .back:   newStates[id] = true
                case .random: newStates[id] = Bool.random()
                }
            }
            self.flipStates = newStates
        }
    }

    // MARK: - Filtering & Sorting
    
    func applyFilters() {
        var predicates: [NSPredicate] = []
        if !selectedMonths.isEmpty {
            predicates.append(NSPredicate(format: "sectionIdentifier IN %@", selectedMonths))
        }
        frc.fetchRequest.predicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        try? frc.performFetch()
        self.sections = frc.sections ?? []
        syncLedger() // Re-sync after fetch
    }

    func toggleMonthFilter(_ month: String) {
        if selectedMonths.contains(month) {
            selectedMonths.remove(month)
        } else {
            selectedMonths.insert(month)
        }
        applyFilters()
    }

    func updateSort(_ mode: SortMode) {
        let sectionSort = NSSortDescriptor(key: "sectionIdentifier", ascending: false)
        switch mode {
        case .recent:
            frc.fetchRequest.sortDescriptors = [sectionSort, NSSortDescriptor(key: "lastModified", ascending: false)]
        case .indexAsc:
            frc.fetchRequest.sortDescriptors = [sectionSort, NSSortDescriptor(key: "index", ascending: true)]
        case .indexDesc:
            frc.fetchRequest.sortDescriptors = [sectionSort, NSSortDescriptor(key: "index", ascending: false)]
        }
        try? frc.performFetch()
        self.sections = frc.sections ?? []
    }

    private func updateAvailableMonths() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "WordStatus")
        request.resultType = .dictionaryResultType
        request.returnsDistinctResults = true
        request.propertiesToFetch = ["sectionIdentifier"]
        
        let results = try? context.fetch(request) as? [[String: String]]
        self.allAvailableMonths = results?.compactMap { $0["sectionIdentifier"] }.sorted(by: >) ?? []
    }

    // MARK: - Date Helpers
    
    func formatFullMonth(_ id: String) -> String {
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
