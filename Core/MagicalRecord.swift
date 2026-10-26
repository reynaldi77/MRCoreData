import Foundation
@preconcurrency import CoreData

/// Pengganti kelas utama MagicalRecord untuk inisialisasi stack Core Data
/// dan menyediakan helper context global yang kompatibel dengan API Obj-C dan Swift.
@objc(MagicalRecord)
public final class MagicalRecord: NSObject {
    
    // MARK: - Singleton / Shared Instance
    public static let shared = MagicalRecord()
    
    /// Persistent Container yang digunakan di balik layar (Core Data modern)
    public private(set) var persistentContainer: NSPersistentContainer?
    
    /// Opsi menghapus store bila model mismatch / migration error
    private static var _shouldDeleteStoreOnModelMismatch: Bool = false
    
    @objc public static var shouldDeleteStoreOnModelMismatch: Bool {
        get { return _shouldDeleteStoreOnModelMismatch }
        set { _shouldDeleteStoreOnModelMismatch = newValue }
    }
    
    /// Default context (viewContext) untuk operasi UI / read di main thread
    @objc public static var defaultContext: NSManagedObjectContext {
        guard let container = shared.persistentContainer else {
            fatalError("MagicalRecord belum diinisialisasi. Panggil MagicalRecord.setupCoreDataStack(...) terlebih dahulu.")
        }
        return container.viewContext
    }
    
    /// Context root saving (mengacu ke default context)
    @objc public static var rootSavingContext: NSManagedObjectContext {
        return defaultContext
    }
    
    private override init() {
        super.init()
    }
    
    // MARK: - Setup Methods (Kompatibel dengan MagicalRecord lama)
    
    /// Setup stack standar Core Data berdasarkan nama model .xcdatamodeld
    @objc(setupCoreDataStackWithModelNamed:)
    @discardableResult
    public static func setupCoreDataStack(withModelNamed modelName: String) -> NSPersistentContainer {
        let container = NSPersistentContainer(name: modelName)
        loadStoreWithMismatchHandling(for: container)
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        shared.persistentContainer = container
        return container
    }
    
    /// Setup stack dengan nama store kustom (Obj-C compatibility)
    @objc(setupCoreDataStackWithStoreNamed:)
    @discardableResult
    public static func setupCoreDataStack(withStoreNamed storeName: String) -> NSPersistentContainer {
        return setupCoreDataStack(withModelNamed: storeName)
    }
    
    /// Setup stack otomatis mencari model yang tersedia di bundle utama
    @objc(setupAutoMigratingCoreDataStack)
    @discardableResult
    public static func setupAutoMigratingCoreDataStack() -> NSPersistentContainer {
        if let modelURL = Bundle.main.urls(forResourcesWithExtension: "momd", subdirectory: nil)?.first {
            let modelName = modelURL.deletingPathExtension().lastPathComponent
            return setupCoreDataStack(withModelNamed: modelName)
        }
        return setupCoreDataStack(withModelNamed: "Model")
    }
    
    /// Helper memuat persistent store dengan penanganan model mismatch (shouldDeleteStoreOnModelMismatch)
    private static func loadStoreWithMismatchHandling(for container: NSPersistentContainer) {
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("⚠️ [MagicalRecord-Ext] Failed to load store: \(error), userInfo: \(error.userInfo)")
                
                // Deteksi model mismatch / migration error
                let isMigrationError = (error.domain == NSCocoaErrorDomain) && (
                    error.code == NSPersistentStoreIncompatibleVersionHashError ||
                    error.code == NSMigrationMissingSourceModelError ||
                    error.code == NSMigrationError
                )
                
                if shouldDeleteStoreOnModelMismatch && isMigrationError, let storeURL = storeDescription.url {
                    print("⚠️ [MagicalRecord-Ext] Incompatible model detected. Deleting store: \(storeURL.path)")
                    deleteStoreFiles(at: storeURL)
                    
                    // Coba load ulang persistent store sekali lagi
                    container.loadPersistentStores { (retryDescription, retryError) in
                        if let retryError = retryError {
                            print("❌ [MagicalRecord-Ext] Failed to recreate store: \(retryError)")
                        } else {
                            print("✅ [MagicalRecord-Ext] Store successfully recreated after mismatch deletion.")
                        }
                    }
                }
            } else {
                print("✅ [MagicalRecord-Ext] Core Data store loaded: \(storeDescription.url?.absoluteString ?? "")")
            }
        }
    }
    
    /// Hapus file database SQLite beserta file sidecar (-shm dan -wal)
    private static func deleteStoreFiles(at url: URL) {
        let fileManager = FileManager.default
        let rawURL = url.path
        let shmPath = rawURL.appending("-shm")
        let walPath = rawURL.appending("-wal")
        
        try? fileManager.removeItem(atPath: rawURL)
        try? fileManager.removeItem(atPath: shmPath)
        try? fileManager.removeItem(atPath: walPath)
    }
    
    /// Bersihkan stack (clean up)
    @objc(cleanUp)
    public static func cleanUp() {
        shared.persistentContainer = nil
    }
    
    // MARK: - Save Helpers (Closure-based, Kompatibel dengan kode lama Obj-C & Swift)
    
    /// Menjalankan perubahan di background context lalu menyimpannya ke persistent store.
    @objc(saveWithBlock:completion:)
    public static func save(
        _ block: @escaping (NSManagedObjectContext) -> Void,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        guard let container = shared.persistentContainer else {
            completion?(false, NSError(domain: "MagicalRecord-Ext", code: -1, userInfo: [NSLocalizedDescriptionKey: "Container not initialized"]))
            return
        }
        
        container.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            block(context)
            
            if context.hasChanges {
                do {
                    try context.save()
                    DispatchQueue.main.async {
                        completion?(true, nil)
                    }
                } catch {
                    print("❌ [MagicalRecord-Ext] Background save failed: \(error)")
                    DispatchQueue.main.async {
                        completion?(false, error)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion?(true, nil)
                }
            }
        }
    }
    
    /// Menyimpan perubahan secara sinkron (blocking) pada context background.
    @objc(saveAndWait:)
    public static func saveAndWait(_ block: @escaping (NSManagedObjectContext) -> Void) {
        guard let container = shared.persistentContainer else { return }
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.performAndWait {
            block(context)
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("❌ [MagicalRecord-Ext] saveAndWait failed: \(error)")
                }
            }
        }
    }
}
