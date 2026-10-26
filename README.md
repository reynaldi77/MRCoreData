# MagicalRecord-Ext

A modern, lightweight Swift drop-in replacement for the classic [MagicalRecord](https://github.com/magicalpanda/MagicalRecord) Core Data library.

---

## 📌 Disclaimer & Credits

> **Note**: This is an independent hobby project. All credit and immense gratitude go to **Saul Mora** and the contributors of the original **[MagicalRecord](https://github.com/magicalpanda/MagicalRecord)** project by Magical Panda Software. Their pioneering work made working with Core Data enjoyable for iOS and macOS developers for over a decade.

---

## 💡 Why This Project Exists

The original MagicalRecord library has been unmaintained for several years. However, many production projects (especially legacy or long-running codebases, including my own) still rely heavily on its intuitive API design (`mr_findFirst`, `mr_findAll`, `mr_createEntity`, `mr_deleteEntity`, etc.).

Rewriting an entire Core Data persistence layer from scratch is often risky, time-consuming, and cost-prohibitive.

**`MagicalRecord-Ext`** was created as a bridge solution:
- **Zero Major Refactoring:** Allows existing codebases to continue functioning with familiar MagicalRecord call semantics without large overhauls.
- **Dual-Layer Interoperability:** Compatible with existing Objective-C (`.m`) code via `@objc(MR_...)` selectors, while simultaneously providing modern, type-safe Swift ergonomics.
- **No Forced Concurrency:** Fully supports classic synchronous calls and closure/block-based background saves so you are not forced to adopt Swift Concurrency (`async/await`) before you are ready.
- **Modern Core Data Foundation:** Backed internally by standard Apple `NSPersistentContainer` (iOS 10+ / macOS 10.12+), eliminating legacy context nesting and coordinator issues.
- **Compiler Clean:** Built to satisfy modern Swift compiler rules (Swift 5.10 / Swift 6) with zero `Sendable` or covariant return warnings.

---

## 📦 Installation via Swift Package Manager (SPM)

You can add `MRCoreData` to your project using Xcode's Swift Package Manager:

1. In Xcode, select **File** > **Add Package Dependencies...**
2. Enter the repository URL:
   ```text
   https://github.com/reynaldi77/MRCoreData.git
   ```
3. In **Dependency Rule**, select **Up to Next Major Version** (or specify branch `main`).
4. Choose **MRCoreData** and add it to your app target.

---

## 🚀 Quick Start

### 1. Stack Initialization

#### In Swift (`AppDelegate.swift`):
```swift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
        // Automatically recreate store on model version hash mismatch during active development
        MagicalRecord.setShouldDeleteStoreOnModelMismatch(true)
        #endif
        
        // Initialize with your .xcdatamodeld name
        MagicalRecord.setupCoreDataStack(withModelNamed: "MyDataModel")
        return true
    }
}
```

#### In Objective-C (`AppDelegate.m`):
```objc
#import "AppDelegate.h"
// Import your module's Swift header, e.g. <YourProject-Swift.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if DEBUG
    [MagicalRecord setShouldDeleteStoreOnModelMismatch:YES];
#endif
    [MagicalRecord setupCoreDataStackWithModelNamed:@"MyDataModel"];
    return YES;
}
@end
```

---

## 🛠 Usage Examples

### 1. Fetching Entities

```swift
// Swift (strongly-typed return value, no casting required!)
if let user = User.mr_findFirst(byAttribute: "email", withValue: "user@example.com") {
    print("Found user: \(user.name ?? "")")
}

let activeUsers: [User] = User.mr_findAllSorted(
    by: "createdAt",
    ascending: false,
    with: NSPredicate(format: "isActive == YES")
)
```

In Objective-C:
```objc
User *user = [User MR_findFirstByAttribute:@"email" withValue:@"user@example.com"];
NSArray *users = [User MR_findAllSortedBy:@"createdAt" ascending:NO withPredicate:[NSPredicate predicateWithFormat:@"isActive == YES"]];
```

### 2. Creating & Deleting Entities

```swift
// Create
guard let item = Item.mr_createEntity() else { return }
item.title = "Grocery"
NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait()

// Delete single entity
item.mr_deleteEntity()

// Delete matching records
Item.mr_deleteAll(matching: NSPredicate(format: "isCompleted == YES"))
```

### 3. Background Saves (Closure / Block)

```swift
MagicalRecord.save({ context in
    let backgroundItem = Item.mr_createEntity(in: context)
    backgroundItem.title = "Synced Item"
}) { success, error in
    if success {
        print("Successfully saved to persistent store!")
    }
}
```

---

## 📁 Project Structure

```
MagicalRecord-Ext/
├── README.md                                    # Project overview & quick start
├── AGENTS.md                                    # Architectural context & AI agent guidelines
├── CHANGELOG.md                                 # Version release history
├── Core/
│   └── MagicalRecord.swift                      # Stack setup & background save execution
└── Extensions/
    ├── NSManagedObject+Finders.swift            # mr_findFirst, mr_findAll & queries
    ├── NSManagedObject+Record.swift             # mr_createEntity, mr_deleteEntity, mr_deleteAll
    ├── NSManagedObject+Aggregation.swift        # mr_count, mr_sum, mr_average, min, max
    ├── NSManagedObject+Requests.swift           # NSFetchRequest & predicate builders
    └── NSManagedObjectContext+Saves.swift       # mr_saveToPersistentStoreAndWait & context getters
```

---

## 📄 License

This project is open-source and intended for educational, personal, and hobbyist use to assist teams in transitioning legacy projects. Please refer to the original MagicalRecord license for historical rights and terms.
