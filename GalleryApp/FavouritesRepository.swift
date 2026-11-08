import CoreData

@MainActor
protocol FavouritesPersisting {
    func load() async throws -> [Photo]
    func setFavourite(_ photo: Photo, enabled: Bool) async throws
}

@MainActor
final class FavouritesRepository: FavouritesPersisting {
    private let container: NSPersistentContainer
    private var loading: Task<Void, Error>?

    init(storeURL: URL? = nil, inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Favourites", managedObjectModel: Self.makeModel())
        let description = NSPersistentStoreDescription()
        if inMemory {
            description.type = NSInMemoryStoreType
        } else {
            description.url = storeURL ?? NSPersistentContainer.defaultDirectoryURL()
                .appendingPathComponent("Favourites.sqlite")
        }
        description.shouldAddStoreAsynchronously = true
        container.persistentStoreDescriptions = [description]
    }

    private func prepare() async throws {
        if let loading { return try await loading.value }
        let container = container
        let task = Task<Void, Error> {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                container.loadPersistentStores { _, error in
                    if let error { continuation.resume(throwing: error) } else { continuation.resume() }
                }
            }
        }
        loading = task
        do {
            try await task.value
        } catch {
            loading = nil
            throw error
        }
    }

    func load() async throws -> [Photo] {
        try await prepare()
        let context = container.viewContext
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Favourite")
            request.sortDescriptors = [NSSortDescriptor(key: "addedAt", ascending: false)]
            return try context.fetch(request).map { object in
                guard let data = object.value(forKey: "payload") as? Data else {
                    throw CocoaError(.coderReadCorrupt)
                }
                return try JSONDecoder().decode(Photo.self, from: data)
            }
        }
    }

    func setFavourite(_ photo: Photo, enabled: Bool) async throws {
        try await prepare()
        let data = try JSONEncoder().encode(photo)
        let context = container.viewContext
        try await context.perform {
            do {
                let request = NSFetchRequest<NSManagedObject>(entityName: "Favourite")
                request.predicate = NSPredicate(format: "id == %@", photo.id)
                let existing = try context.fetch(request)
                if enabled {
                    let object = existing.first ?? NSEntityDescription.insertNewObject(
                        forEntityName: "Favourite", into: context
                    )
                    object.setValue(photo.id, forKey: "id")
                    object.setValue(data, forKey: "payload")
                    if object.value(forKey: "addedAt") == nil { object.setValue(Date(), forKey: "addedAt") }
                } else {
                    existing.forEach(context.delete)
                }
                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    private static func makeModel() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = "Favourite"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [
            attribute("id", type: .stringAttributeType),
            attribute("payload", type: .binaryDataAttributeType),
            attribute("addedAt", type: .dateAttributeType)
        ]
        entity.uniquenessConstraints = [["id"]]
        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }

    private static func attribute(_ name: String, type: NSAttributeType) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = false
        return attribute
    }
}
