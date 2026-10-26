import Foundation
@preconcurrency import CoreData

public extension NSManagedObject {
    
    // MARK: - Swift-First Methods (Generic & Default Parameters)
    
    /// Membuat entity baru di dalam context yang ditentukan (default: MagicalRecord.defaultContext)
    static func mr_createEntity(in context: NSManagedObjectContext = MagicalRecord.defaultContext) -> Self {
        return context.performAndWait {
            Self(context: context)
        }
    }
    
    // MARK: - Single Entity Deletion
    
    /// Menghapus entity saat ini dari context-nya
    @discardableResult
    func mr_deleteEntity() -> Bool {
        guard let context = self.managedObjectContext else { return false }
        let targetID = self.objectID
        return context.performAndWait {
            let objectToDelete = context.object(with: targetID)
            context.delete(objectToDelete)
            return true
        }
    }
    
    /// Menghapus entity dari context tertentu
    @discardableResult
    func mr_deleteEntity(in context: NSManagedObjectContext) -> Bool {
        let targetID = self.objectID
        return context.performAndWait {
            let objectInContext = context.object(with: targetID)
            context.delete(objectInContext)
            return true
        }
    }
    
    // MARK: - Batch / Predicate Deletion (mr_deleteAll)
    
    /// Menghapus semua entity yang cocok dengan predicate opsional (jika nil, menghapus seluruh entity)
    @discardableResult
    static func mr_deleteAll(
        matching predicate: NSPredicate? = nil,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> Bool {
        let entityName = self.mr_entityName
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        
        return context.performAndWait {
            let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDelete.resultType = .resultTypeObjectIDs
            
            do {
                if let result = try context.execute(batchDelete) as? NSBatchDeleteResult,
                   let objectIDs = result.result as? [NSManagedObjectID] {
                    let changes = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                    return true
                }
            } catch {
                // Fallback manual jika SQLite batch delete gagal atau menggunakan in-memory store
            }
            
            do {
                let objects = try context.fetch(fetchRequest) as? [NSManagedObject] ?? []
                for object in objects {
                    context.delete(object)
                }
                return true
            } catch {
                print("❌ [MagicalRecord-Ext] Failed to delete matching records for \(entityName): \(error)")
                return false
            }
        }
    }
    
    /// Menghapus seluruh entity dari tipe ini pada context tertentu (alias truncateAll)
    @discardableResult
    static func mr_deleteAll(in context: NSManagedObjectContext = MagicalRecord.defaultContext) -> Bool {
        return mr_deleteAll(matching: nil, in: context)
    }
    
    /// Alias dari mr_deleteAll(matching:in:) agar kompatibel dengan MagicalRecord lama
    @discardableResult
    static func mr_deleteAllMatchingPredicate(
        _ predicate: NSPredicate,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> Bool {
        return mr_deleteAll(matching: predicate, in: context)
    }
    
    /// Truncate seluruh data entity (alias mr_deleteAll)
    @discardableResult
    static func mr_truncateAll(in context: NSManagedObjectContext = MagicalRecord.defaultContext) -> Bool {
        return mr_deleteAll(matching: nil, in: context)
    }
    
    // MARK: - Context Switching / Object Transfer
    
    /// Memindahkan/mengambil referensi instance objek ini di context yang berbeda
    func mr_inContext(_ otherContext: NSManagedObjectContext) -> Self? {
        if self.managedObjectContext === otherContext {
            return self
        }
        
        let targetID = self.objectID
        return otherContext.performAndWait {
            do {
                let object = try otherContext.existingObject(with: targetID)
                return object as? Self
            } catch {
                print("⚠️ [MagicalRecord-Ext] Could not find object in other context: \(error)")
                return nil
            }
        }
    }
    
    // MARK: - Objective-C Interoperability Bridge (MR_...)
    
    @objc(MR_entityName)
    static func MR_entityName() -> String {
        return mr_entityName
    }
    
    @objc(MR_createEntity)
    static func MR_createEntity() -> NSManagedObject? {
        return mr_createEntity(in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_createEntityInContext:)
    static func MR_createEntity(inContext context: NSManagedObjectContext) -> NSManagedObject? {
        return mr_createEntity(in: context)
    }
    
    @objc(MR_deleteEntity)
    @discardableResult
    func MR_deleteEntity() -> Bool {
        return mr_deleteEntity()
    }
    
    @objc(MR_deleteEntityInContext:)
    @discardableResult
    func MR_deleteEntity(inContext context: NSManagedObjectContext) -> Bool {
        return mr_deleteEntity(in: context)
    }
    
    @objc(MR_deleteInContext:)
    @discardableResult
    func MR_deleteInContext(_ context: NSManagedObjectContext) -> Bool {
        return mr_deleteEntity(in: context)
    }
    
    @objc(MR_deleteAllMatchingPredicate:)
    @discardableResult
    static func MR_deleteAllMatchingPredicate(_ predicate: NSPredicate) -> Bool {
        return mr_deleteAll(matching: predicate, in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_deleteAllMatchingPredicate:inContext:)
    @discardableResult
    static func MR_deleteAllMatchingPredicate(_ predicate: NSPredicate, inContext context: NSManagedObjectContext) -> Bool {
        return mr_deleteAll(matching: predicate, in: context)
    }
    
    @objc(MR_deleteAll)
    @discardableResult
    static func MR_deleteAll() -> Bool {
        return mr_deleteAll(matching: nil, in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_deleteAllInContext:)
    @discardableResult
    static func MR_deleteAll(inContext context: NSManagedObjectContext) -> Bool {
        return mr_deleteAll(matching: nil, in: context)
    }
    
    @objc(MR_truncateAll)
    @discardableResult
    static func MR_truncateAll() -> Bool {
        return mr_truncateAll(in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_truncateAllInContext:)
    @discardableResult
    static func MR_truncateAll(inContext context: NSManagedObjectContext) -> Bool {
        return mr_truncateAll(in: context)
    }
    
    @objc(MR_inContext:)
    func MR_inContext(_ otherContext: NSManagedObjectContext) -> NSManagedObject? {
        return mr_inContext(otherContext)
    }
}
