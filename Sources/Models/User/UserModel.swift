import Fluent
import Vapor

public final class UserModel: Content & Model, @unchecked Sendable {
 public static let schema = "user"
 // https://docs.vapor.codes/fluent/relations/
 @ID public var id: UUID?
 @OptionalChild(for: \UserCredentials.$model) var credentials: UserCredentials?
 /// A unique username used for identifying a user.
 @Field(key: "name") public var name: String
 /// A custom username used to personalize a user.
 @OptionalField(key: "tag") public var tag: String?
 public init() {}
}

extension UserModel {
 public func databaseDescription(on db: Database) -> String {
  """
  id: \(id.readable)
  credentials: 
  \(try! $credentials.get(on: db).wait()!.databaseDescription(on: db).split(separator: .newline).map { " \($0)\n" }.joined())
  name: \(name)
  tag: \(tag.readable)
  """
 }
}

// MARK: Migration
public struct UserMigration: MigrationProtocol {
 public func prepare(on database: any Database) async throws {
  try await database.schema(UserModel.schema)
   .id()
   .field("name", .string, .required)
   .field("tag", .string)
   .unique(on: "name")
   .create()
 }

 public func revert(on database: Database) async throws {
  try await database.schema(UserModel.schema).delete()
 }
}

public extension MigrationProtocol where Self == UserMigration {
 static var user: Self { Self() }
}
