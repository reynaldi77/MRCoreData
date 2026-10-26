import Foundation
@preconcurrency import CoreData

public extension NSManagedObject {
    
    // MARK: - Swift-First Find First (Type-Safe Generic Self)
    
    /// Mengambil objek pertama yang ditemukan
    static func mr_findFirst(in context: NSManagedObjectContext = MagicalRecord.defaultContext) -> Self? {
        return mr_findFirst(with: nil, sortedBy: nil, ascending: true, in: context)
    }
    
    /// Mengambil objek pertama yang cocok dengan NSPredicate
    static func mr_findFirst(
        with predicate: NSPredicate?,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> Self? {
        return mr_findFirst(with: predicate, sortedBy: nil, ascending: true, in: context)
    }
    
    /// Mengambil objek pertama dengan predicate dan sorting
    static func mr_findFirst(
        with predicate: NSPredicate? = nil,
        sortedBy sortTerm: String? = nil,
        ascending: Bool = true,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> Self? {
        let entityName = self.mr_entityName
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = predicate
        request.fetchLimit = 1
        if let sortTerm = sortTerm {
            request.sortDescriptors = [NSSortDescriptor(key: sortTerm, ascending: ascending)]
        }
        
        return context.performAndWait {
            do {
                let results = try context.fetch(request)
                return results.first as? Self
            } catch {
                print("❌ [MagicalRecord-Ext] mr_findFirst failed: \(error)")
                return nil
            }
        }
    }
    
    /// Mencari objek pertama berdasarkan atribut tertentu (key & value)
    static func mr_findFirst(
        byAttribute attribute: String,
        withValue value: Any,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> Self? {
        let predicate = NSPredicate(format: "%K == %@", argumentArray: [attribute, value])
        return mr_findFirst(with: predicate, in: context)
    }
    
    // MARK: - Swift-First Find All (Generic <T: NSManagedObject>)
    
    /// Mengambil semua record
    static func mr_findAll<T: NSManagedObject>(in context: NSManagedObjectContext = MagicalRecord.defaultContext) -> [T] {
        return mr_findAll(with: nil, sortedBy: nil, ascending: true, in: context)
    }
    
    /// Mengambil semua record yang cocok dengan NSPredicate
    static func mr_findAll<T: NSManagedObject>(
        with predicate: NSPredicate?,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> [T] {
        return mr_findAll(with: predicate, sortedBy: nil, ascending: true, in: context)
    }
    
    /// Mengambil semua record dengan sorting
    static func mr_findAllSorted<T: NSManagedObject>(
        by sortTerm: String,
        ascending: Bool = true,
        with predicate: NSPredicate? = nil,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> [T] {
        return mr_findAll(with: predicate, sortedBy: sortTerm, ascending: ascending, in: context)
    }
    
    /// Mengambil semua record dengan predicate, sorting, dan context
    static func mr_findAll<T: NSManagedObject>(
        with predicate: NSPredicate? = nil,
        sortedBy sortTerm: String? = nil,
        ascending: Bool = true,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> [T] {
        let entityName = self.mr_entityName
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = predicate
        if let sortTerm = sortTerm {
            request.sortDescriptors = [NSSortDescriptor(key: sortTerm, ascending: ascending)]
        }
        
        return context.performAndWait {
            do {
                if let fetched = try context.fetch(request) as? [T] {
                    return fetched
                }
            } catch {
                print("❌ [MagicalRecord-Ext] mr_findAll failed: \(error)")
            }
            return []
        }
    }
    
    /// Mencari semua record berdasarkan atribut tertentu
    static func mr_findByAttribute<T: NSManagedObject>(
        _ attribute: String,
        withValue value: Any,
        andOrderBy sortTerm: String? = nil,
        ascending: Bool = true,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> [T] {
        let predicate = NSPredicate(format: "%K == %@", argumentArray: [attribute, value])
        return mr_findAll(with: predicate, sortedBy: sortTerm, ascending: ascending, in: context)
    }
    
    // MARK: - Objective-C Interoperability Bridge (MR_...)
    
    @objc(MR_findFirst)
    static func MR_findFirst() -> NSManagedObject? {
        return mr_findFirst(in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_findFirstInContext:)
    static func MR_findFirst(inContext context: NSManagedObjectContext) -> NSManagedObject? {
        return mr_findFirst(in: context)
    }
    
    @objc(MR_findFirstWithPredicate:)
    static func MR_findFirst(withPredicate predicate: NSPredicate?) -> NSManagedObject? {
        return mr_findFirst(with: predicate, in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_findFirstWithPredicate:inContext:)
    static func MR_findFirst(withPredicate predicate: NSPredicate?, inContext context: NSManagedObjectContext) -> NSManagedObject? {
        return mr_findFirst(with: predicate, in: context)
    }
    
    @objc(MR_findFirstWithPredicate:sortedBy:ascending:)
    static func MR_findFirst(withPredicate predicate: NSPredicate?, sortedBy property: String?, ascending: Bool) -> NSManagedObject? {
        return mr_findFirst(with: predicate, sortedBy: property, ascending: ascending, in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_findFirstWithPredicate:sortedBy:ascending:inContext:)
    static func MR_findFirst(withPredicate predicate: NSPredicate?, sortedBy property: String?, ascending: Bool, inContext context: NSManagedObjectContext) -> NSManagedObject? {
        return mr_findFirst(with: predicate, sortedBy: property, ascending: ascending, in: context)
    }
    
    @objc(MR_findFirstByAttribute:withValue:)
    static func MR_findFirst(byAttribute attribute: String, withValue value: Any) -> NSManagedObject? {
        return mr_findFirst(byAttribute: attribute, withValue: value, in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_findFirstByAttribute:withValue:inContext:)
    static func MR_findFirst(byAttribute attribute: String, withValue value: Any, inContext context: NSManagedObjectContext) -> NSManagedObject? {
        return mr_findFirst(byAttribute: attribute, withValue: value, in: context)
    }
    
    @objc(MR_findAll)
    static func MR_findAll() -> [NSManagedObject] {
        return mr_findAll(in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_findAllInContext:)
    static func MR_findAll(inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return mr_findAll(in: context)
    }
    
    @objc(MR_findAllWithPredicate:)
    static func MR_findAll(withPredicate predicate: NSPredicate?) -> [NSManagedObject] {
        return mr_findAll(with: predicate, in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_findAllWithPredicate:inContext:)
    static func MR_findAll(withPredicate predicate: NSPredicate?, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return mr_findAll(with: predicate, in: context)
    }
    
    @objc(MR_findAllSortedBy:ascending:)
    static func MR_findAll(sortedBy sortTerm: String, ascending: Bool) -> [NSManagedObject] {
        return mr_findAllSorted(by: sortTerm, ascending: ascending, in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_findAllSortedBy:ascending:inContext:)
    static func MR_findAll(sortedBy sortTerm: String, ascending: Bool, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return mr_findAllSorted(by: sortTerm, ascending: ascending, in: context)
    }
    
    @objc(MR_findAllSortedBy:ascending:withPredicate:)
    static func MR_findAll(sortedBy sortTerm: String?, ascending: Bool, withPredicate predicate: NSPredicate?) -> [NSManagedObject] {
        return mr_findAll(with: predicate, sortedBy: sortTerm, ascending: ascending, in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_findAllSortedBy:ascending:withPredicate:inContext:)
    static func MR_findAll(sortedBy sortTerm: String?, ascending: Bool, withPredicate predicate: NSPredicate?, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return mr_findAll(with: predicate, sortedBy: sortTerm, ascending: ascending, in: context)
    }
    
    @objc(MR_findByAttribute:withValue:)
    static func MR_findByAttribute(_ attribute: String, withValue value: Any) -> [NSManagedObject] {
        return mr_findByAttribute(attribute, withValue: value, in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_findByAttribute:withValue:inContext:)
    static func MR_findByAttribute(_ attribute: String, withValue value: Any, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return mr_findByAttribute(attribute, withValue: value, in: context)
    }
    
    @objc(MR_findByAttribute:withValue:andOrderBy:ascending:)
    static func MR_findByAttribute(_ attribute: String, withValue value: Any, andOrderBy sortTerm: String?, ascending: Bool) -> [NSManagedObject] {
        return mr_findByAttribute(attribute, withValue: value, andOrderBy: sortTerm, ascending: ascending, in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_findByAttribute:withValue:andOrderBy:ascending:inContext:)
    static func MR_findByAttribute(_ attribute: String, withValue value: Any, andOrderBy sortTerm: String?, ascending: Bool, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return mr_findByAttribute(attribute, withValue: value, andOrderBy: sortTerm, ascending: ascending, in: context)
    }
}
