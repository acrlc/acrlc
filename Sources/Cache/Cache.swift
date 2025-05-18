import Vapor
import Fluent

protocol CacheProtocol {
 func callAsFunction(_ app: Application) throws
}

protocol Cacheable {}
protocol CacheableContent: Content, Cacheable, Equatable {}
protocol CacheableModel: CacheableContent, Model {
// static var migration: AsyncMigration { get }
// static func uncache(_ request: Request, for id: IDValue) async throws -> Self?
}
