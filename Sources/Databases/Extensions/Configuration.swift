@_exported import Configuration
import struct Vapor.Environment

public extension Configuration {
 // to be set by the remote server by default, must be nil if using localhost
 var url: String? { Environment.get("DATABASE_URL") }
 var hostname: String {
  Environment.get("DATABASE_HOST") ?? "localhost"
 }

 var database: String {
  Environment.get("DATABASE_NAME") ?? "postgres"
 }

 var username: String {
  Environment.get("DATABASE_USERNAME") ?? "postgres"
 }

 /// - Warning: Before starting the server for production a secure password
 /// needs to be manually entered.
 var password: String {
  Environment.get("DATABASE_PASSWORD") ?? "password"
 }

 var redis: String {
  Environment.get("REDIS_URL") ?? "redis://127.0.0.1:6379"
 }

 // set to reference your service urls
 var web: String {
  Environment.get("WEB_URL") ?? "http://localhost:8080"
 }

 var api: String {
  Environment.get("API_URL") ?? web
 }

 var email: String? {
  Environment.get("NO_REPLY_EMAIL")
 }
}

extension Configuration: @retroactive CustomStringConvertible {
 public var description: String {
  """
   — DATABASE NAME \"\(database)\"
   — DATABASE URL \"\(url ?? api)\"
   — HOSTNAME \"\(hostname)\"
   — USERNAME \"\(username)\"
   — PASSWORD \"\(password)\"
   — REDIS \"\(redis)\"
   — WEB URL \"\(web)\"
   — API URL \"\(api)\"
   — NOREPLY \"\(email ?? .empty)\"
  """
 }
}

extension Configuration: @retroactive CustomDebugStringConvertible {
 public var debugDescription: String {
  """
   — DATABASE NAME \"\(database)\"
   — DATABASE URL \"\(url ?? api)\"
   — HOSTNAME \"\(hostname)\"
   — USERNAME \"\(username)\"
   — PASSWORD \"\(password)\"
   — REDIS \"\(redis)\"
   — WEB URL \"\(web)\"
   — API URL \"\(api)\"
   — NOREPLY \"\(email.readable)\"
  """
 }
 
 public func printConfiguration() {
  self("\n\(debugDescription)")
 }
}
