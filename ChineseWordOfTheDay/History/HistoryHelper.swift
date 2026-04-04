import SwiftUI
import CoreData
import Combine
import CoreDataModels

class HistoryHelper: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    internal let context: NSManagedObjectContext
    private var frc: NSFetchedResultsController<WordStatus>!
    private var cancellables = Set<AnyCancellable>()
    
    @Published var sections: [NSFetchedResultsSectionInfo] = []
    @Published var searchText: String = ""
    @Published var selectedMonths: Set<String> = []
    @Published var allAvailableMonths: [String] = []
    
    let flipTrigger = PassthroughSubject<FlipAction, Never>()
    
    enum FlipAction { case allFront, allBack, random }
    enum SortMode { case recent, indexAsc, indexDesc }

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        setupFRC()
        setupSearchObserver()
        updateAvailableMonths()
    }

    private func setupFRC() {
        let request: NSFetchRequest<WordStatus> = WordStatus.fetchRequest()
        // Primary sort by month (section), secondary by time learned
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

    private func setupSearchObserver() {
        $searchText.debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in self?.applyFilters() }
            .store(in: &cancellables)
    }

    func applyFilters() {
        var predicates: [NSPredicate] = []
        
        if !searchText.isEmpty {
            // Search by index or characters stored on the status
            let search = NSPredicate(format: "traditional CONTAINS[cd] %@ OR index == %d", searchText, Int(searchText) ?? -1)
            predicates.append(search)
        }
        
        if !selectedMonths.isEmpty {
            predicates.append(NSPredicate(format: "sectionIdentifier IN %@", selectedMonths))
        }
        
        frc.fetchRequest.predicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        try? frc.performFetch()
        self.sections = frc.sections ?? []
    }

    func toggleMonthFilter(_ month: String) {
        if selectedMonths.contains(month) { selectedMonths.remove(month) }
        else { selectedMonths.insert(month) }
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

    func bulkFlip(_ action: FlipAction) { flipTrigger.send(action) }

    private func updateAvailableMonths() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "WordStatus")
        request.resultType = .dictionaryResultType
        request.returnsDistinctResults = true
        request.propertiesToFetch = ["sectionIdentifier"]
        let results = try? context.fetch(request) as? [[String: String]]
        self.allAvailableMonths = results?.compactMap { $0["sectionIdentifier"] }.sorted(by: >) ?? []
    }
}
