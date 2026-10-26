import Foundation
@preconcurrency import CoreData

public extension NSManagedObject {
    
    // MARK: - Entity Name
    
    /// Mengembalikan nama entity secara otomatis dari class name
    static var mr_entityName: String {
        return String(describing: self)
    }
    
    // MARK: - Fetch Request Creation (Swift Friendly)
    
    /// Membuat NSFetchRequest dengan tipe generic Self
    static func mr_requestAll() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest<NSFetchRequestResult>(entityName: mr_entityName)
    }
    
    /// Membuat NSFetchRequest bertipe khusus Self
    static func mr_createFetchRequest() -> NSFetchRequest<NSManagedObject> {
        return NSFetchRequest<NSManagedObject>(entityName: mr_entityName)
    }
    
    /// Membuat fetch request dengan NSPredicate opsional
    static func mr_requestAll(with predicate: NSPredicate?) -> NSFetchRequest<NSFetchRequestResult> {
        let request = mr_requestAll()
        request.predicate = predicate
        return request
    }
    
    /// Membuat fetch request dengan predicate dan urutan (sort descriptors)
    static func mr_requestAllSorted(
        by sortTerm: String?,
        ascending: Bool,
        with predicate: NSPredicate? = nil
    ) -> NSFetchRequest<NSFetchRequestResult> {
        let request = mr_requestAll(with: predicate)
        if let sortTerm = sortTerm {
            let sortDescriptor = NSSortDescriptor(key: sortTerm, ascending: ascending)
            request.sortDescriptors = [sortDescriptor]
        }
        return request
    }
    
    /// Helper membuat predicate format string secara aman
    static func mr_predicate(format: String, _ args: CVarArg...) -> NSPredicate {
        return withVaList(args) { valist in
            NSPredicate(format: format, arguments: valist)
        }
    }
    
    // MARK: - Objective-C Interoperability Bridge (MR_...)
    
    @objc(MR_requestAll)
    static func MR_requestAll() -> NSFetchRequest<NSFetchRequestResult> {
        return mr_requestAll()
    }
    
    @objc(MR_requestAllWithPredicate:)
    static func MR_requestAll(with predicate: NSPredicate?) -> NSFetchRequest<NSFetchRequestResult> {
        return mr_requestAll(with: predicate)
    }
    
    @objc(MR_requestAllSortedBy:ascending:withPredicate:)
    static func MR_requestAllSorted(by sortTerm: String?, ascending: Bool, with predicate: NSPredicate?) -> NSFetchRequest<NSFetchRequestResult> {
        return mr_requestAllSorted(by: sortTerm, ascending: ascending, with: predicate)
    }
}
