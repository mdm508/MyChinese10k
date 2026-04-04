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
    
    let flipTrigger = PassthroughSubject<FlipAction, Never>()
    
    enum FlipAction { case allFront, allBack, random }
    enum SortMode { case recent, indexAsc, indexDesc }

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        setupFRC()
        updateAvailableMonths()
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
        }
    }

    // MARK: - Logic & Filtering
    
    func applyFilters() {
        var predicates: [NSPredicate] = []
        if !selectedMonths.isEmpty {
            predicates.append(NSPredicate(format: "sectionIdentifier IN %@", selectedMonths))
        }
        frc.fetchRequest.predicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        try? frc.performFetch()
        self.sections = frc.sections ?? []
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

    func bulkFlip(_ action: FlipAction) {
        flipTrigger.send(action)
    }

    private func updateAvailableMonths() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "WordStatus")
        request.resultType = .dictionaryResultType
        request.returnsDistinctResults = true
        request.propertiesToFetch = ["sectionIdentifier"]
        
        let results = try? context.fetch(request) as? [[String: String]]
        self.allAvailableMonths = results?.compactMap { $0["sectionIdentifier"] }.sorted(by: >) ?? []
    }

    // MARK: - Date Formatting Helpers
    
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
