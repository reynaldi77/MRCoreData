# AGENTS.md — MagicalRecord-Ext Documentation & AI Context Guide

This document is intended for human developers and **AI Agents** (LLM, Copilot, Cursor, Windsurf, Claude Code, Antigravity, etc.) to immediately understand the architecture, design principles, change history, and usage patterns of the `MagicalRecord-Ext` module without needing to inspect the codebase from scratch.

---

## 1. Background & Purpose
`MagicalRecord` (Objective-C) is a popular Core Data wrapper library that is now **deprecated / unmaintained**.
`MagicalRecord-Ext` was created as a pure Swift **drop-in replacement** to ease the migration of existing codebases toward modern Swift without breaking legacy Objective-C call sites or forcing an immediate migration to Swift Concurrency.

### Core Architectural Principles:
1. **Dual-Layer Architecture (Obj-C & Swift Compatibility):**
   - **Swift Layer (Modern & Ergonomic):** Utilizes default parameter values (`= nil`, `= true`) and generic return types:
     - Single Object: `Self?` (e.g. `User.mr_findFirst() -> User?`).
     - Collections / Arrays: Method generics `<T: NSManagedObject> ... -> [T]` (e.g. `User.mr_findAll() -> [User]`). *Note: Never use `[Self]` for collections in non-final class extensions because Swift disallows covariant Self arrays.*
   - **Objective-C Bridge Layer:** Exposes selectors prefixed with `@objc(MR_...)` using concrete return types (`NSManagedObject?`, `[NSManagedObject]`, `Bool`, `UInt`) and explicit method overloads (without default parameter values) so that `.m` Objective-C files can continue calling methods uninterrupted.
   - **NEVER REMOVE either of these two layers** when modifying the extensions! The codebase is in an incremental transition phase from Objective-C to Swift.
2. **Never Force Modern Swift Features (Fallback-Friendly):** Synchronous execution and completion handler (closure)-based saves remain first-class citizens. The codebase does NOT force migration to Swift Concurrency (`async/await`).
3. **Clean Concurrency & Zero Sendable Warnings:**
   - In `context.performAndWait`, always return values directly from the closure:
     ```swift
     return context.performAndWait {
         Self(context: context)
     }
     ```
   - Avoid capturing non-Sendable local variables (`var entity: Self!`) or `self` (capture `self.objectID`, which is Sendable/thread-safe).
   - Configure `NSFetchRequest` outside the `context.performAndWait` closure so that `NSPredicate?` is not captured inside `@Sendable` closures.
4. **Modern Core Data Foundation:** Backed by Apple's standard `NSPersistentContainer` (iOS 10+ / macOS 10.12+), replacing outdated `NSPersistentStoreCoordinator` boilerplate and nested contexts.
5. **Auto-Delete SQLite Store on Model Mismatch:** Supports `shouldDeleteStoreOnModelMismatch` and `setShouldDeleteStoreOnModelMismatch(_:)` to automatically remove and recreate SQLite store files (`.sqlite`, `-wal`, `-shm`) when incompatible model version hash errors occur during development.

---

## 2. Module Structure

```
MagicalRecord-Ext/
├── Package.swift                                # Swift Package Manager manifest (MRCoreData)
├── README.md                                    # Project overview & quick start
├── AGENTS.md                                    # Architectural context & instructions for AI Agents & Developers
├── CHANGELOG.md                                 # Version-by-version release history
├── Core/
│   └── MagicalRecord.swift                      # Stack setup, model mismatch handling & closure save helpers
└── Extensions/
    ├── NSManagedObject+Finders.swift            # mr_findFirst, mr_findAll + Obj-C MR_ selectors
    ├── NSManagedObject+Record.swift             # mr_createEntity, mr_deleteEntity, mr_deleteAll, mr_truncateAll + Obj-C bridge
    ├── NSManagedObject+Aggregation.swift        # mr_count, mr_sum, mr_average, min, max + Obj-C bridge
    ├── NSManagedObject+Requests.swift           # FetchRequest builder & predicate helpers + Obj-C bridge
    └── NSManagedObjectContext+Saves.swift       # mr_saveToPersistentStoreAndWait, async save, context getters
```

---

## 3. API Mapping: Objective-C vs Swift

| Operation | Objective-C (from `.m` files) | Swift (from `.swift` files) |
|---|---|---|
| **Setup Stack** | `[MagicalRecord setupCoreDataStackWithModelNamed:@"Model"];` | `MagicalRecord.setupCoreDataStack(withModelNamed: "Model")` |
| **Model Mismatch** | `[MagicalRecord setShouldDeleteStoreOnModelMismatch:YES];` | `MagicalRecord.setShouldDeleteStoreOnModelMismatch(true)` |
| **Default Context** | `[NSManagedObjectContext MR_defaultContext]` | `NSManagedObjectContext.mr_default()` |
| **Create Entity** | `[Person MR_createEntity]` | `Person.mr_createEntity()` *(Generic Self?)* |
| **Find First** | `[Person MR_findFirst]` | `Person.mr_findFirst()` *(Return type: Person?)* |
| **Find All** | `[Person MR_findAll]` | `Person.mr_findAll()` *(Return type: [Person])* |
| **Find All Sorted** | `[Person MR_findAllSortedBy:@"index" ascending:YES withPredicate:p]` | `Person.mr_findAllSorted(by: "index", ascending: true, with: p)` |
| **Find by Attribute** | `[Person MR_findFirstByAttribute:@"id" withValue:@123]` | `Person.mr_findFirst(byAttribute: "id", withValue: 123)` |
| **Delete Single Entity** | `[person MR_deleteEntity]` | `person.mr_deleteEntity()` |
| **Delete All Matching** | `[Person MR_deleteAllMatchingPredicate:p]` | `Person.mr_deleteAll(matching: p)` / `mr_deleteAllMatchingPredicate(p)` |
| **Delete All / Truncate** | `[Person MR_deleteAll]` / `[Person MR_truncateAll]` | `Person.mr_deleteAll()` / `Person.mr_truncateAll()` |
| **Count** | `[Person MR_countOfEntities]` | `Person.mr_count()` |
| **Sync Save** | `[context MR_saveToPersistentStoreAndWait]` | `context.mr_saveToPersistentStoreAndWait()` |
| **Closure Save** | `[MagicalRecord saveWithBlock:^(NSManagedObjectContext *ctx) {...} completion:^(BOOL success, NSError *err) {...}];` | `MagicalRecord.save({ ctx in ... }, completion: { success, error in ... })` |

---

## 4. Usage Examples

### Initialization in AppDelegate (Swift)
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    #if DEBUG
    // Automatically recreate database when model changes during development
    MagicalRecord.setShouldDeleteStoreOnModelMismatch(true)
    #endif
    
    MagicalRecord.setupCoreDataStack(withModelNamed: "MyDataModel")
    return true
}
```

### Initialization in AppDelegate (Objective-C)
```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if DEBUG
    [MagicalRecord setShouldDeleteStoreOnModelMismatch:YES];
#endif
    [MagicalRecord setupCoreDataStackWithModelNamed:@"MyDataModel"];
    return YES;
}
```

### CRUD Example (Swift)
```swift
// 1. Create
let user = User.mr_createEntity()
user.name = "John Doe"
user.age = 30
NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait()

// 2. Fetch / Read (Directly strongly-typed as User)
if let found = User.mr_findFirst(byAttribute: "name", withValue: "John Doe") {
    print("Found user: \(found.name ?? "")")
}

let activeUsers: [User] = User.mr_findAllSorted(by: "age", ascending: true, with: NSPredicate(format: "age >= 18"))

// 3. Delete
user.mr_deleteEntity()
NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait()
```

---

## 5. Strict Guidelines for AI Agents
When tasked with extending, modifying, or migrating code utilizing `MagicalRecord-Ext`:

1. **ALWAYS PROVIDE OBJECTIVE-C FALLBACK BRIDGES (`@objc(MR_...)`) FOR ANY NEW FUNCTION:**
   - The project still actively compiles Objective-C (`.m`) source files.
   - Every time a new function is added in Swift, you **MUST** provide an `@objc` overload matching the legacy MagicalRecord selector names (without default parameters, using concrete return types such as `NSManagedObject?`, `[NSManagedObject]`, `Bool`, or `UInt`).
   - Never implement a pure Swift function without considering its Objective-C bridge counterpart!
2. **DO NOT Remove Generic `Self` & Default Parameters from the Swift Layer:**
   - These features ensure that as Objective-C files are retired, the Swift call sites remain modern, clean, and type-safe without requiring subsequent refactoring.
3. **DO NOT Use `[Self]` for Collections in Class Extensions:**
   - Always use generic method parameters `<T: NSManagedObject> ... -> [T]` to avoid covariant return type compiler errors.
4. **Maintain Zero Sendable / Concurrency Warnings:**
   - Always use `@preconcurrency import CoreData` when importing CoreData in this module.
   - Configure `NSFetchRequest` prior to entering `context.performAndWait` blocks to prevent capturing non-Sendable `NSPredicate?` instances.
   - Return values directly from `context.performAndWait { return ... }` rather than mutating outer scope variables.
5. **Import & Module Integration Rules:**
   - **Swift:** Recommend `@_exported import MRCoreData` in a single shared file (e.g., `GlobalImports.swift`) so developers do not need to add `import MRCoreData` to every Swift file manually.
   - **Objective-C:** **DO NOT** instruct users to place `@import MRCoreData;` inside `<Project>-Bridging-Header.h` (this causes circular dependency errors with Swift SPM packages). Users must add `@import MRCoreData;` directly in each `.m` implementation file that needs it.
6. **Preserve Core Data Thread-Safety:**
   - Always wrap entity property mutations and fetch executions inside `context.performAndWait` or `context.perform` to avoid Core Data concurrency violations.
7. **Log All Changes in `CHANGELOG.md` & `AGENTS.md` (STRICTLY IN ENGLISH):**
   - Every modification, fix, or addition must be promptly documented in both [CHANGELOG.md](file:///Users/detik/Downloads/AntiGravityDump/MRCoreData/CHANGELOG.md) and [AGENTS.md](file:///Users/detik/Downloads/AntiGravityDump/MRCoreData/AGENTS.md).
   - **Language Rule:** Both `CHANGELOG.md` and `AGENTS.md` **MUST ALWAYS be written and maintained in English** to ensure consistent readability across different international AI models and developer environments.
8. **Strict Versioning, Tagging & GitHub Release Guidelines:**
   Whenever performing a version bump (e.g. from `1.4.3` to `1.4.4` or higher):
   - **Step 1: Determine Semantic Versioning (`MAJOR.MINOR.PATCH`)**:
     - `PATCH`: Bug fixes, minor type refinement, or backward-compatible doc updates.
     - `MINOR`: New features, method overloads, or extensions (always providing `@objc` bridge counterpart).
     - `MAJOR`: Breaking changes or fundamental architectural shifts.
   - **Step 2: Update `CHANGELOG.md`**:
     - Add the new version header `## [X.Y.Z] - YYYY-MM-DD` and categorize changes under `### Added`, `### Changed`, or `### Fixed` in English.
   - **Step 3: Commit Changes**:
     ```bash
     git add CHANGELOG.md AGENTS.md <affected-files>
     git commit -m "chore(release): bump version to X.Y.Z"
     ```
   - **Step 4: Create Annotated Git Tag**:
     - An annotated Git tag matching the exact version number is required so Xcode Swift Package Manager can resolve versioning rules (such as *"Up to Next Major Version"*):
     ```bash
     git tag -a X.Y.Z -m "Release X.Y.Z"
     ```
   - **Step 5: Push Commits and Tags to Remote**:
     ```bash
     git push origin <branch-name>
     git push origin X.Y.Z
     ```
   - **Step 6: Publish GitHub Release**:
     - Create a GitHub Release so the release appears on GitHub's sidebar under "Releases" with release notes:
       - **Via GitHub Web UI:** Go to repository Releases -> "Draft a new release" -> choose tag `X.Y.Z` -> copy release notes from `CHANGELOG.md` -> click "Publish release".
       - **Via GitHub CLI (`gh`):**
         ```bash
         gh release create X.Y.Z --title "vX.Y.Z" --notes-file <notes.md>
         ```
