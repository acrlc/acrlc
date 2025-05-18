// MARK: - Postgres
import FluentPostgresDriver
import PostgresKit
import class Vapor.Request
import struct Logging.Logger
import class Vapor.Application
import Fluent

public typealias DatabaseProtocols = [any DatabaseProtocol]

public protocol DatabaseProtocol {
 static var id: DatabaseID { get }
 var id: DatabaseID { get }
 var name: String? { get }
 var logLevel: Logger.Level? { get }
 var isDefault: Bool? { get }
 func callAsFunction(
  _ config: Configuration, _ app: Application, _ logLevel: Logger.Level
 ) throws
}

public extension DatabaseProtocol {
 var id: DatabaseID {
  if let name {
   DatabaseID(string: "\(Self.id.string).\(name)")
  } else {
   Self.id
   }
 }
 /// The database registered with `id`.
 func database(with request: Request) -> (any Database) {
  request.application.db(id)
 }
}

public struct PostgresDatabase: DatabaseProtocol {
 public static var id: DatabaseID { .psql }
 public var name: String?
 public var logLevel: Logger.Level?
 public var isDefault: Bool?

 public func callAsFunction(
  _ config: Configuration, _ app: Application, _ logLevel: Logger.Level
 ) throws {
  // check if url was set by a remote server
  guard let url = config.url else {
   // access local server
   app.databases.use(
    .postgres(
     configuration:
      SQLPostgresConfiguration(
       hostname: config.hostname,
       username: config.username,
       password: config.password,
       database: name ?? config.database,
       tls: .disable
      ),
     sqlLogLevel: logLevel
    ), as: id, isDefault: isDefault
   )
   return
  }
  // access the remote server
  try app.databases
   .use(.postgres(url: url, sqlLogLevel: logLevel), as: id, isDefault: isDefault)
 }
}

public extension DatabaseProtocol where Self == PostgresDatabase {
 static var postgres: Self { Self() }
 static func postgres(
  name: String? = nil,
  logLevel: Logger.Level? = nil, isDefault: Bool? = nil
 ) -> Self {
  Self(name: name, logLevel: logLevel, isDefault: isDefault)
 }
}
