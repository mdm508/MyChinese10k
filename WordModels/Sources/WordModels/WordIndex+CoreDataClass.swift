import CoreData

public class WordIndex: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WordIndex> {
        return NSFetchRequest<WordIndex>(entityName: "WordIndex")
    }
    @NSManaged public var current: Int64
}
