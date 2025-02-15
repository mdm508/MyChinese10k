import CoreData

extension WordIndex {
    @NSManaged public var current: Int64
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WordIndex> {
        return NSFetchRequest<WordIndex>(entityName: "WordIndex")
    }
}
