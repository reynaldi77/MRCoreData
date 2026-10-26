# Changelog — MagicalRecord-Ext

All notable changes to the `MagicalRecord-Ext` module are documented in this file to keep developers and AI agents fully up to date with code evolution.

---

## [1.4.0] - 2026-10-26

### Added
- **Swift Package Manager (SPM) Support**:
  - Added [Package.swift](file:///Users/reynaldiwidianto/Documents/project/MagicalRecord-Ext/Package.swift) defining the `MRCoreData` library target (compatible with iOS 12+, macOS 10.13+, tvOS 12+, and watchOS 4+).
  - Xcode projects can now directly add this repository as an SPM dependency via `https://github.com/reynaldi77/MRCoreData.git`.
  - Added installation guide in [README.md](file:///Users/reynaldiwidianto/Documents/project/MagicalRecord-Ext/README.md).

---

## [1.3.1] - 2026-10-26

### Fixed
- **CoreData Import Preconcurrency Warning**:
  - Replaced `import CoreData` with `@preconcurrency import CoreData` across all files in `MagicalRecord-Ext`.
  - Suppresses compiler warning *"Add '@preconcurrency' to suppress 'Sendable'-related warnings from module 'CoreData'"* emitted by Swift 5.10 / Swift 6 without modifying runtime behavior or requiring async migration.

---

## [1.3.0] - 2026-10-26

### Added
- **Complete `mr_deleteAll` Method Family**:
  - `mr_deleteAll(matching:in:)`
  - `mr_deleteAll(in:)`
  - `mr_deleteAllMatchingPredicate(_:in:)`
  - Full Objective-C bridge selectors:
    - `@objc(MR_deleteAllMatchingPredicate:)`
    - `@objc(MR_deleteAllMatchingPredicate:inContext:)`
    - `@objc(MR_deleteAll)`
    - `@objc(MR_deleteAllInContext:)`
    - `@objc(MR_deleteInContext:)`
- **Resolution for `predicate` Sendable Capture Warning**:
  - `NSFetchRequest` objects are now created and configured before entering `context.performAndWait`, preventing `NSPredicate?` from being captured directly inside `@Sendable` closures.
  - Eliminates the warning *"Capture of 'predicate' with non-Sendable type 'NSPredicate?' in a '@Sendable' closure"*.

---

## [1.2.1] - 2026-10-26

### Added
- **`with predicate: NSPredicate?` Parameter to `mr_findAllSorted`**:
  - Added the signature `mr_findAllSorted(by:ascending:with:in:)` to ensure 100% compatibility with legacy Swift MagicalRecord call sites (e.g. `Kanal.mr_findAllSorted(by: "index", ascending: true, with: predicate)`).
  - Resolves the compiler error *"Extra argument 'with' in call"*.

---

## [1.2.0] - 2026-10-26

### Fixed
- **Covariant `[Self]` Compiler Error on `mr_findAll`**:
  - Fixed compiler error *"Covariant 'Self' or 'Self?' can only appear at the top level of method result type"*.
  - Solution: Replaced array return types with generic method parameters `<T: NSManagedObject> ... -> [T]`. Now `User.mr_findAll(...)` automatically returns a strongly-typed `[User]` without compilation errors.
- **Sendable Closure Warning Cleanups (Swift Strict Concurrency)**:
  - Fixed warnings *"Capture of 'entity' with non-Sendable type 'Self?' in a '@Sendable' closure"* and *"Capture of 'self' with non-Sendable type 'NSManagedObject' in a '@Sendable' closure"*.
  - Solution: Leveraged direct return values from `context.performAndWait { return ... }` and captured `self.objectID` (which is thread-safe / Sendable) instead of mutating outer variables or capturing `self`.
  - This fix maintains 100% synchronous behavior and **does not force the project to adopt async/await**.

---

## [1.1.0] - 2026-10-26

### Added
- **Full Objective-C Interoperability (Dual-Layer Architecture)**:
  - Added `@objc(MR_...)` selectors across all extensions (`NSManagedObject+Finders`, `NSManagedObject+Record`, `NSManagedObject+Aggregation`, `NSManagedObject+Requests`, `NSManagedObjectContext+Saves`).
  - Objective-C `.m` files can now call `[Entity MR_findFirst]`, `[Entity MR_createEntity]`, `[Entity MR_truncateAll]`, `[context MR_saveToPersistentStoreAndWait]`, etc., without compilation errors.
  - **Preserves 100% of modern Swift ergonomics** (Generic return types and default parameters `nil`, `true`, etc.).
- **Model Mismatch Option & Auto-Delete Store**:
  - Added `MagicalRecord.shouldDeleteStoreOnModelMismatch` and `MagicalRecord.setShouldDeleteStoreOnModelMismatch(_:)`.
  - Implemented automatic deletion of SQLite database files (`.sqlite`, `-wal`, `-shm`) when incompatible version hash mismatch errors (`NSPersistentStoreIncompatibleVersionHashError`, `NSMigrationMissingSourceModelError`, `NSMigrationError`) are encountered, followed by automatic store re-creation matching legacy MagicalRecord behavior.
- **Objective-C Selector Aliases**:
  - `[MagicalRecord setupCoreDataStackWithStoreNamed:]`
  - `[MagicalRecord setupCoreDataStackWithModelNamed:]`
  - `[MagicalRecord setupAutoMigratingCoreDataStack]`
  - `[MagicalRecord cleanUp]`
  - `[MagicalRecord saveWithBlock:completion:]`
  - `[MagicalRecord saveAndWait:]`

---

## [1.0.0] - 2026-10-26

### Added
- Initial release of the modern Swift drop-in replacement for the unmaintained `MagicalRecord` library.
- Built on top of `NSPersistentContainer`.
- `NSManagedObject+Finders.swift` extension with generic type-safety.
- `NSManagedObject+Record.swift` extension for entity creation, deletion, truncation, and context switching.
- `NSManagedObject+Aggregation.swift` extension for count, sum, average, min, and max.
- `NSManagedObject+Requests.swift` extension for `NSFetchRequest` and predicate building.
- `NSManagedObjectContext+Saves.swift` extension for synchronous saves, closure-based background saves, and optional `async/await` overload.
- AI & developer context guide in `AGENTS.md`.
