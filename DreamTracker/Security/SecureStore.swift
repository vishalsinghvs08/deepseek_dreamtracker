import Foundation
import CoreData

public protocol SecureStoreProtocol {
    func saveDream(_ dream: Dream) async throws
    func fetchDreams() async throws -> [Dream]
    func deleteDream(id: UUID) async throws
    func fetchAllDreams(includeDeleted: Bool) async throws -> [Dream]
    func fetchPendingSyncDreams() async throws -> [Dream]
    func permanentlyDeleteDream(id: UUID) async throws
}

public final class SecureStore: SecureStoreProtocol {
    internal let persistentContainer: NSPersistentContainer
    private let backgroundContext: NSManagedObjectContext
    
    public init(storeURL: URL? = nil) {
        let model = Self.createManagedObjectModel()
        persistentContainer = NSPersistentContainer(name: "DreamTrackerStore", managedObjectModel: model)
        
        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        
        if let storeURL = storeURL {
            description.url = storeURL
        } else {
            let defaultURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent("DreamTracker.sqlite")
            description.url = defaultURL
        }
        
        // 1. Persistent history tracking enabled
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        // 2. SQLite file encryption enabled via data protection
        description.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        
        // Enable automatic store migration
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load persistent store: \(error)")
            }
        }
        
        // 3. Background context usage for database writes and reads
        backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        let dreamEntity = NSEntityDescription()
        dreamEntity.name = "DreamEntity"
        dreamEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        
        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType
        titleAttr.isOptional = false
        
        let contentAttr = NSAttributeDescription()
        contentAttr.name = "content"
        contentAttr.attributeType = .stringAttributeType
        contentAttr.isOptional = false
        
        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = false
        
        let lucidityScoreAttr = NSAttributeDescription()
        lucidityScoreAttr.name = "lucidityScore"
        lucidityScoreAttr.attributeType = .integer32AttributeType
        lucidityScoreAttr.isOptional = false
        
        let isLucidAttr = NSAttributeDescription()
        isLucidAttr.name = "isLucid"
        isLucidAttr.attributeType = .booleanAttributeType
        isLucidAttr.isOptional = false
        
        let tagsAttr = NSAttributeDescription()
        tagsAttr.name = "tagsData"
        tagsAttr.attributeType = .binaryDataAttributeType
        tagsAttr.isOptional = true
        
        let updatedAtAttr = NSAttributeDescription()
        updatedAtAttr.name = "updatedAt"
        updatedAtAttr.attributeType = .dateAttributeType
        updatedAtAttr.isOptional = false
        updatedAtAttr.defaultValue = Date()
        
        let isDeletedAttr = NSAttributeDescription()
        isDeletedAttr.name = "isDeleted"
        isDeletedAttr.attributeType = .booleanAttributeType
        isDeletedAttr.isOptional = false
        isDeletedAttr.defaultValue = false
        
        let isPendingSyncAttr = NSAttributeDescription()
        isPendingSyncAttr.name = "isPendingSync"
        isPendingSyncAttr.attributeType = .booleanAttributeType
        isPendingSyncAttr.isOptional = false
        isPendingSyncAttr.defaultValue = false
        
        dreamEntity.properties = [
            idAttr,
            titleAttr,
            contentAttr,
            dateAttr,
            lucidityScoreAttr,
            isLucidAttr,
            tagsAttr,
            updatedAtAttr,
            isDeletedAttr,
            isPendingSyncAttr
        ]
        
        model.entities = [dreamEntity]
        return model
    }
    
    public func saveDream(_ dream: Dream) async throws {
        try await backgroundContext.perform { [backgroundContext] in
            let request = NSFetchRequest<NSManagedObject>(entityName: "DreamEntity")
            request.predicate = NSPredicate(format: "id == %@", dream.id as CVarArg)
            request.fetchLimit = 1
            
            let existingObjects = try backgroundContext.fetch(request)
            let managedObject: NSManagedObject
            
            if let existing = existingObjects.first {
                managedObject = existing
            } else {
                guard let entity = NSEntityDescription.entity(forEntityName: "DreamEntity", in: backgroundContext) else {
                    throw SecurityError.encryptionFailed
                }
                managedObject = NSManagedObject(entity: entity, insertInto: backgroundContext)
            }
            
            managedObject.setValue(dream.id, forKey: "id")
            managedObject.setValue(dream.title, forKey: "title")
            managedObject.setValue(dream.content, forKey: "content")
            managedObject.setValue(dream.date, forKey: "date")
            managedObject.setValue(Int32(dream.lucidityScore), forKey: "lucidityScore")
            managedObject.setValue(dream.isLucid, forKey: "isLucid")
            managedObject.setValue(dream.updatedAt, forKey: "updatedAt")
            managedObject.setValue(dream.isDeleted, forKey: "isDeleted")
            managedObject.setValue(dream.isPendingSync, forKey: "isPendingSync")
            
            // MEDIUM-1 fix: use try instead of try? so encoding failure propagates
            let tagsData = try JSONEncoder().encode(dream.tags)
            managedObject.setValue(tagsData, forKey: "tagsData")
            
            if backgroundContext.hasChanges {
                try backgroundContext.save()
            }
        }
    }
    
    public func fetchDreams() async throws -> [Dream] {
        try await backgroundContext.perform { [backgroundContext] in
            let request = NSFetchRequest<NSManagedObject>(entityName: "DreamEntity")
            request.predicate = NSPredicate(format: "isDeleted == %@", false as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            let results = try backgroundContext.fetch(request)
            var dreams: [Dream] = []
            
            for object in results {
                guard let id = object.value(forKey: "id") as? UUID,
                      let title = object.value(forKey: "title") as? String,
                      let content = object.value(forKey: "content") as? String,
                      let date = object.value(forKey: "date") as? Date,
                      let lucidityScore = object.value(forKey: "lucidityScore") as? Int32,
                      let isLucid = object.value(forKey: "isLucid") as? Bool else {
                    continue
                }
                
                let tags: [String]
                if let tagsData = object.value(forKey: "tagsData") as? Data,
                   let decodedTags = try? JSONDecoder().decode([String].self, from: tagsData) {
                    tags = decodedTags
                } else {
                    tags = []
                }
                
                let updatedAt = object.value(forKey: "updatedAt") as? Date ?? Date()
                let isDeleted = object.value(forKey: "isDeleted") as? Bool ?? false
                let isPendingSync = object.value(forKey: "isPendingSync") as? Bool ?? false
                
                let dream = Dream(
                    id: id,
                    title: title,
                    content: content,
                    date: date,
                    lucidityScore: Int(lucidityScore),
                    isLucid: isLucid,
                    tags: tags,
                    updatedAt: updatedAt,
                    isDeleted: isDeleted,
                    isPendingSync: isPendingSync
                )
                dreams.append(dream)
            }
            
            return dreams
        }
    }
    
    public func fetchAllDreams(includeDeleted: Bool) async throws -> [Dream] {
        try await backgroundContext.perform { [backgroundContext] in
            let request = NSFetchRequest<NSManagedObject>(entityName: "DreamEntity")
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            if !includeDeleted {
                request.predicate = NSPredicate(format: "isDeleted == %@", false as CVarArg)
            }
            
            let results = try backgroundContext.fetch(request)
            var dreams: [Dream] = []
            
            for object in results {
                guard let id = object.value(forKey: "id") as? UUID,
                      let title = object.value(forKey: "title") as? String,
                      let content = object.value(forKey: "content") as? String,
                      let date = object.value(forKey: "date") as? Date,
                      let lucidityScore = object.value(forKey: "lucidityScore") as? Int32,
                      let isLucid = object.value(forKey: "isLucid") as? Bool else {
                    continue
                }
                
                let tags: [String]
                if let tagsData = object.value(forKey: "tagsData") as? Data,
                   let decodedTags = try? JSONDecoder().decode([String].self, from: tagsData) {
                    tags = decodedTags
                } else {
                    tags = []
                }
                
                let updatedAt = object.value(forKey: "updatedAt") as? Date ?? Date()
                let isDeleted = object.value(forKey: "isDeleted") as? Bool ?? false
                let isPendingSync = object.value(forKey: "isPendingSync") as? Bool ?? false
                
                let dream = Dream(
                    id: id,
                    title: title,
                    content: content,
                    date: date,
                    lucidityScore: Int(lucidityScore),
                    isLucid: isLucid,
                    tags: tags,
                    updatedAt: updatedAt,
                    isDeleted: isDeleted,
                    isPendingSync: isPendingSync
                )
                dreams.append(dream)
            }
            
            return dreams
        }
    }
    
    public func fetchPendingSyncDreams() async throws -> [Dream] {
        try await backgroundContext.perform { [backgroundContext] in
            let request = NSFetchRequest<NSManagedObject>(entityName: "DreamEntity")
            request.predicate = NSPredicate(format: "isPendingSync == %@", true as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            let results = try backgroundContext.fetch(request)
            var dreams: [Dream] = []
            
            for object in results {
                guard let id = object.value(forKey: "id") as? UUID,
                      let title = object.value(forKey: "title") as? String,
                      let content = object.value(forKey: "content") as? String,
                      let date = object.value(forKey: "date") as? Date,
                      let lucidityScore = object.value(forKey: "lucidityScore") as? Int32,
                      let isLucid = object.value(forKey: "isLucid") as? Bool else {
                    continue
                }
                
                let tags: [String]
                if let tagsData = object.value(forKey: "tagsData") as? Data,
                   let decodedTags = try? JSONDecoder().decode([String].self, from: tagsData) {
                    tags = decodedTags
                } else {
                    tags = []
                }
                
                let updatedAt = object.value(forKey: "updatedAt") as? Date ?? Date()
                let isDeleted = object.value(forKey: "isDeleted") as? Bool ?? false
                let isPendingSync = object.value(forKey: "isPendingSync") as? Bool ?? false
                
                let dream = Dream(
                    id: id,
                    title: title,
                    content: content,
                    date: date,
                    lucidityScore: Int(lucidityScore),
                    isLucid: isLucid,
                    tags: tags,
                    updatedAt: updatedAt,
                    isDeleted: isDeleted,
                    isPendingSync: isPendingSync
                )
                dreams.append(dream)
            }
            
            return dreams
        }
    }
    
    public func deleteDream(id: UUID) async throws {
        try await backgroundContext.perform { [backgroundContext] in
            let request = NSFetchRequest<NSManagedObject>(entityName: "DreamEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            let results = try backgroundContext.fetch(request)
            if let objectToUpdate = results.first {
                objectToUpdate.setValue(true, forKey: "isDeleted")
                objectToUpdate.setValue(Date(), forKey: "updatedAt")
                objectToUpdate.setValue(true, forKey: "isPendingSync")
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
                }
            }
        }
    }
    
    public func permanentlyDeleteDream(id: UUID) async throws {
        try await backgroundContext.perform { [backgroundContext] in
            let request = NSFetchRequest<NSManagedObject>(entityName: "DreamEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            let results = try backgroundContext.fetch(request)
            if let objectToDelete = results.first {
                backgroundContext.delete(objectToDelete)
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
                }
            }
        }
    }
    
    public func destroy() throws {
        let coordinator = persistentContainer.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            try coordinator.remove(store)
            if let url = store.url {
                try FileManager.default.removeItem(at: url)
                // MEDIUM-4 fix: WAL/SHM files may hold recent plaintext writes — surface failures
                let shmURL = url.deletingPathExtension().appendingPathExtension("sqlite-shm")
                let walURL = url.deletingPathExtension().appendingPathExtension("sqlite-wal")
                if FileManager.default.fileExists(atPath: shmURL.path) {
                    try FileManager.default.removeItem(at: shmURL)
                }
                if FileManager.default.fileExists(atPath: walURL.path) {
                    try FileManager.default.removeItem(at: walURL)
                }
            }
        }
    }
}
