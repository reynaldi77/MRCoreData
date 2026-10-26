import Foundation
@preconcurrency import CoreData

public extension NSManagedObjectContext {
    
    // MARK: - Legacy Context Getters (Swift Friendly)
    
    /// Mengambil default context (viewContext)
    static func mr_default() -> NSManagedObjectContext {
        return MagicalRecord.defaultContext
    }
    
    /// Mengambil root saving context
    static func mr_rootSaving() -> NSManagedObjectContext {
        return MagicalRecord.rootSavingContext
    }
    
    /// Membuat private background context baru
    static func mr_newPrivateQueueContext() -> NSManagedObjectContext {
        guard let container = MagicalRecord.shared.persistentContainer else {
            fatalError("MagicalRecord belum diinisialisasi.")
        }
        return container.newBackgroundContext()
    }
    
    /// Alias pembuatan background context baru
    static func mr_newBackgroundContext() -> NSManagedObjectContext {
        return mr_newPrivateQueueContext()
    }
    
    // MARK: - Save Methods (Swift Friendly)
    
    /// Menyimpan context saat ini secara sinkron (blocking).
    func mr_saveToPersistentStoreAndWait() {
        self.performAndWait {
            guard self.hasChanges else { return }
            do {
                try self.save()
                
                var parent = self.parent
                while let currentParent = parent {
                    currentParent.performAndWait {
                        if currentParent.hasChanges {
                            do {
                                try currentParent.save()
                            } catch {
                                print("❌ [MagicalRecord-Ext] Error saving parent context: \(error)")
                            }
                        }
                    }
                    parent = currentParent.parent
                }
            } catch {
                print("❌ [MagicalRecord-Ext] mr_saveToPersistentStoreAndWait failed: \(error)")
            }
        }
    }
    
    /// Menyimpan context saat ini secara asynchronous dengan completion handler callback.
    func mr_saveToPersistentStore(completion: ((Bool, Error?) -> Void)? = nil) {
        self.perform {
            guard self.hasChanges else {
                DispatchQueue.main.async { completion?(true, nil) }
                return
            }
            
            do {
                try self.save()
                
                if let parent = self.parent {
                    parent.mr_saveToPersistentStore(completion: completion)
                } else {
                    DispatchQueue.main.async { completion?(true, nil) }
                }
            } catch {
                print("❌ [MagicalRecord-Ext] mr_saveToPersistentStore failed: \(error)")
                DispatchQueue.main.async { completion?(false, error) }
            }
        }
    }
    
    /// Menyimpan context lokal saja (tanpa menjalar ke parent store)
    func mr_saveOnlySelfAndWait() {
        self.performAndWait {
            guard self.hasChanges else { return }
            do {
                try self.save()
            } catch {
                print("❌ [MagicalRecord-Ext] mr_saveOnlySelfAndWait failed: \(error)")
            }
        }
    }
    
    // MARK: - Modern Swift Concurrency (Optional Overload)
    
    /// Overload opsional untuk project yang sudah mengaktifkan Swift Concurrency
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func mr_saveToPersistentStoreAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.mr_saveToPersistentStore { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Objective-C Interop Selectors (MR_...)
    
    @objc(MR_defaultContext)
    static func MR_defaultContext() -> NSManagedObjectContext {
        return mr_default()
    }
    
    @objc(MR_rootSavingContext)
    static func MR_rootSavingContext() -> NSManagedObjectContext {
        return mr_rootSaving()
    }
    
    @objc(MR_newPrivateQueueContext)
    static func MR_newPrivateQueueContext() -> NSManagedObjectContext {
        return mr_newPrivateQueueContext()
    }
    
    @objc(MR_saveToPersistentStoreAndWait)
    func MR_saveToPersistentStoreAndWait() {
        mr_saveToPersistentStoreAndWait()
    }
    
    @objc(MR_saveToPersistentStoreWithCompletion:)
    func MR_saveToPersistentStoreWithCompletion(_ completion: ((Bool, Error?) -> Void)?) {
        mr_saveToPersistentStore(completion: completion)
    }
    
    @objc(MR_saveOnlySelfAndWait)
    func MR_saveOnlySelfAndWait() {
        mr_saveOnlySelfAndWait()
    }
}
