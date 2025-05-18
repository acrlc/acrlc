import protocol FluentKit.AsyncMigration
@_exported import Databases

public typealias MigrationProtocols = [any MigrationProtocol]

public protocol MigrationProtocol: AsyncMigration {
 // The database to use for migration. If nil, uses the default database.
 var database: DatabaseProtocol? { get }
}

public extension MigrationProtocol {
 var database: DatabaseProtocol? { nil }
}

