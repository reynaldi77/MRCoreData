import Foundation
@preconcurrency import CoreData

public extension NSManagedObject {
    
    // MARK: - Swift-First Aggregation (Type-Safe & Default Parameters)
    
    /// Menghitung jumlah record dari entity ini
    static func mr_count(in context: NSManagedObjectContext = MagicalRecord.defaultContext) -> Int {
        return mr_count(with: nil, in: context)
    }
    
    /// Menghitung jumlah record yang cocok dengan predicate
    static func mr_count(
        with predicate: NSPredicate?,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> Int {
        let entityName = self.mr_entityName
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = predicate
        
        return context.performAndWait {
            do {
                return try context.count(for: request)
            } catch {
                print("❌ [MagicalRecord-Ext] mr_count failed: \(error)")
                return 0
            }
        }
    }
    
    /// Memeriksa apakah ada setidaknya satu record
    static func mr_hasAtLeastOneRecord(in context: NSManagedObjectContext = MagicalRecord.defaultContext) -> Bool {
        return mr_count(in: context) > 0
    }
    
    /// Menghitung agregasi nilai numerik dari attribute tertentu
    static func mr_aggregate(
        function: String,
        onAttribute attribute: String,
        with predicate: NSPredicate? = nil,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> Any? {
        let entityName = self.mr_entityName
        let request = NSFetchRequest<NSDictionary>(entityName: entityName)
        request.resultType = .dictionaryResultType
        request.predicate = predicate
        
        let keyPathExpression = NSExpression(forKeyPath: attribute)
        let expression = NSExpression(forFunction: function, arguments: [keyPathExpression])
        
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = "aggregateValue"
        expressionDescription.expression = expression
        expressionDescription.expressionResultType = .undefinedAttributeType
        
        request.propertiesToFetch = [expressionDescription]
        
        return context.performAndWait {
            do {
                let results = try context.fetch(request)
                return results.first?["aggregateValue"]
            } catch {
                print("❌ [MagicalRecord-Ext] mr_aggregate (\(function)) failed: \(error)")
                return nil
            }
        }
    }
    
    /// Menghitung jumlah total (Sum) dari attribute numerik
    static func mr_sum(
        of attribute: String,
        with predicate: NSPredicate? = nil,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> NSNumber? {
        return mr_aggregate(function: "sum:", onAttribute: attribute, with: predicate, in: context) as? NSNumber
    }
    
    /// Menghitung rata-rata (Average) dari attribute numerik
    static func mr_average(
        of attribute: String,
        with predicate: NSPredicate? = nil,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> NSNumber? {
        return mr_aggregate(function: "average:", onAttribute: attribute, with: predicate, in: context) as? NSNumber
    }
    
    /// Mengambil nilai minimum dari attribute
    static func mr_min(
        of attribute: String,
        with predicate: NSPredicate? = nil,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> Any? {
        return mr_aggregate(function: "min:", onAttribute: attribute, with: predicate, in: context)
    }
    
    /// Mengambil nilai maksimum dari attribute
    static func mr_max(
        of attribute: String,
        with predicate: NSPredicate? = nil,
        in context: NSManagedObjectContext = MagicalRecord.defaultContext
    ) -> Any? {
        return mr_aggregate(function: "max:", onAttribute: attribute, with: predicate, in: context)
    }
    
    // MARK: - Objective-C Interoperability Bridge (MR_...)
    
    @objc(MR_countOfEntities)
    static func MR_countOfEntities() -> UInt {
        return UInt(mr_count(in: MagicalRecord.defaultContext))
    }
    
    @objc(MR_countOfEntitiesWithContext:)
    static func MR_countOfEntities(withContext context: NSManagedObjectContext) -> UInt {
        return UInt(mr_count(in: context))
    }
    
    @objc(MR_countOfEntitiesWithPredicate:)
    static func MR_countOfEntities(withPredicate predicate: NSPredicate?) -> UInt {
        return UInt(mr_count(with: predicate, in: MagicalRecord.defaultContext))
    }
    
    @objc(MR_countOfEntitiesWithPredicate:inContext:)
    static func MR_countOfEntities(withPredicate predicate: NSPredicate?, inContext context: NSManagedObjectContext) -> UInt {
        return UInt(mr_count(with: predicate, in: context))
    }
    
    @objc(MR_hasAtLeastOneEntity)
    static func MR_hasAtLeastOneEntity() -> Bool {
        return mr_hasAtLeastOneRecord(in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_hasAtLeastOneEntityInContext:)
    static func MR_hasAtLeastOneEntity(inContext context: NSManagedObjectContext) -> Bool {
        return mr_hasAtLeastOneRecord(in: context)
    }
    
    @objc(MR_aggregateOperation:onAttribute:withPredicate:)
    static func MR_aggregateOperation(
        _ function: String,
        onAttribute attributeName: String,
        withPredicate predicate: NSPredicate?
    ) -> Any? {
        return mr_aggregate(function: function, onAttribute: attributeName, with: predicate, in: MagicalRecord.defaultContext)
    }
    
    @objc(MR_aggregateOperation:onAttribute:withPredicate:inContext:)
    static func MR_aggregateOperation(
        _ function: String,
        onAttribute attributeName: String,
        withPredicate predicate: NSPredicate?,
        inContext context: NSManagedObjectContext
    ) -> Any? {
        return mr_aggregate(function: function, onAttribute: attributeName, with: predicate, in: context)
    }
}
