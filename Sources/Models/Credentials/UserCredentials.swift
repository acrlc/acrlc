import Fluent
import Vapor

public final class UserCredentials: Model & Authenticatable, @unchecked Sendable {
 public static let schema = "user_credentials"
 @ID public var id: UUID?
 @Parent(key: "model_id") public var model: UserModel
 /// Array of tokens used to authenticate session access across different
 ///  browsers. Also, contains specific authentication details per request.
 @Children(for: \.$parent) public var tokens: [UserToken]
 /// - Note: All personal data is encrypted and can only be accessed per request
 /// using symmetric pairs with a rotating keychain. Transfers are sent using
 /// an AES.GCM sealed box with nonce.
 /// When making requests a valid payload must exist on the device and server or
 /// else session and/or privileged access should be denied/restricted.
 /// Tokens can be used for different purposes, which should be determined by
 /// the request.
 @Timestamp(key: "created", on: .create) public var dateCreated: Date!
 @Timestamp(key: "modified", on: .update) public var dateModified: Date?
 @Timestamp(key: "deleted", on: .update) public var dateDeleted: Date?
 public init() {}
}

public extension UserCredentials {
 func databaseDescription(on db: Database) -> String {
  """
  id: \(id.readable)
  model: \(try! $model.get(on: db).wait().id.readable)
  tokens: 
  \((try? $tokens.get(on: db).wait()).readable.split(separator: .newline).map { " \($0)\n" }.joined())
  created: \(dateCreated.readable)
  modified: \(dateModified.readable)
  deleted: \(dateDeleted.readable)
  """
 }
}

public struct UserCredentialsMigration: MigrationProtocol, @unchecked Sendable {
 public func prepare(on database: any Database) async throws {
  try await database.schema(UserCredentials.schema)
   .id()
   .field(
    "model_id",
    .uuid,
    .references(UserModel.schemaOrAlias, "id", onDelete: .restrict)
   )
   .field("created", .datetime, .required)
   .field("modified", .datetime)
   .field("deleted", .datetime)
   .create()
 }

 public func revert(on database: Database) async throws {
  try await database.schema(UserCredentials.schema).delete()
 }
}

public extension MigrationProtocol where Self == UserCredentialsMigration {
 static var userCredentials: Self { Self() }
}

// MARK: Tokens
public final class UserToken: Content & Model, @unchecked Sendable {
 public static let schema = "user_token"
 @ID(key: .id)
 public var id: UUID?
 @Parent(key: "parent") public var parent: UserCredentials
 /// The company or vendor of the secure token data used to authenticate an app.
 @Field(key: "agent") public var agent: String
 @Field(key: "info") public var info: [String: Data]
 /// A symmetric key used to create a password to signature authorization
 /// for accessing secure data and creating sessions on the database
 /// Sessions can't be started without this key and passwords can't be reset
 /// without email access. It's used to sign web tokens and login with a
 /// a password. It should never be empty, even when creating a new account.
 // TODO: possibly, all secure data using main queued rotating server key
 @Field(key: "key") public var key: String
 @Timestamp(key: "created", on: .create) public var dateCreated: Date!
 @Timestamp(key: "modified", on: .update) public var dateModified: Date?
 @Field(key: "exipired") public var dateExpired: Date?
 public init() {}
}

public struct UserTokenMigration: MigrationProtocol, @unchecked Sendable {
 public func prepare(on database: any Database) async throws {
  try await database.schema(UserToken.schema)
   .id()
   .field(
    "parent",
    .uuid,
    .references(UserCredentials.schemaOrAlias, "id", onDelete: .cascade)
   )
   .field("agent", .string, .required)
   .field("info", .dictionary(of: .json))
   .field("key", .string, .required)
   .field("created", .datetime, .required)
   .field("modified", .datetime)
   .field("expired", .datetime)
   .create()
 }

 public func revert(on database: Database) async throws {
  try await database.schema(UserToken.schema).delete()
 }
}

public extension MigrationProtocol where Self == UserTokenMigration {
 static var userTokens: Self { Self() }
}

// MARK: Authentication
extension UserToken: ModelTokenAuthenticatable {
 public static var valueKey: KeyPath<UserToken, Field<String>> {
  \.$key
 }

 public static var userKey: KeyPath<UserToken, Parent<UserCredentials>> {
  \.$parent
 }

 public var isValid: Bool { dateExpired == nil ? false : dateExpired! >= .now }
}
