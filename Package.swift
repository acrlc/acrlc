// swift-tools-version: 6.1
import PackageDescription

let package = Package(
 name: "miniServer",
 platforms: [.macOS(.v14)],
 products: [
  .library(name: "Databases", targets: ["Databases"]),
  .library(name: "Migrations", targets: ["Migrations"]),
  .library(name: "Encryption", targets: ["Encryption"]),
  .library(name: "Cache", targets: ["Cache"]),
  .library(name: "Models", targets: ["Models"]),
  .library(name: "Queue", targets: ["Queue"]),
  .library(name: "Routes", targets: ["Routes"]),
  .library(name: "Server", targets: ["Server"]),
  .executable(name: "Run", targets: ["Run"])
 ],
 dependencies: [
  .package(url: "https://github.com/acrlc/Configuration.git", branch: "main"),
  .package(url: "https://github.com/acrlc/Command.git", branch: "main"),
  .package(url: "https://github.com/acrlc/Time.git", branch: "main"),
  .package(url: "https://github.com/acrlc/Acrylic.git", branch: "main"),

  // MARK: Server

  .package(url: "https://github.com/vapor/vapor.git", from: "4.102.1"),

  // MARK: Database

  .package(url: "https://github.com/vapor/postgres-kit.git", from: "2.13.5"),
  .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.9.2"),

  // MARK: Mapping

  .package(url: "https://github.com/vapor/fluent.git", from: "4.11.0"),

  // MARK: Queues

  .package(url: "https://github.com/vapor/queues.git", from: "1.15.0"),

  // MARK: Caching

  .package(url: "https://github.com/vapor/redis.git", from: "4.11.0"),
  .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.1.1"),

  // MARK: Encryption

  .package(url: "https://github.com/apple/swift-crypto.git", from: "3.5.2"),

  // MARK: Authentication

  .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.13.4"),
 ],
 targets: [
  .target(
   name: "Databases", dependencies: [
    "Configuration",
    .product(name: "Fluent", package: "fluent"),
    .product(name: "Vapor", package: "vapor"),
    .product(name: "PostgresKit", package: "postgres-kit"),
    .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
   ]
  ),
  .target(
   name: "Migrations",
   dependencies: [
    "Databases",
    .product(name: "Fluent", package: "fluent"),
    .product(name: "Vapor", package: "vapor"),
    .product(name: "PostgresKit", package: "postgres-kit"),
    .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
   ]
  ),
  .target(
   name: "Encryption",
   dependencies: [
   ]
  ),
  .target(
   name: "Cache",
   dependencies: [
    .product(name: "Fluent", package: "fluent"),
    .product(name: "Vapor", package: "vapor"),
    .product(name: "PostgresKit", package: "postgres-kit"),
    .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
   ]
  ),
  .target(
   name: "Models",
   dependencies: [
    "Migrations",
    .product(name: "Fluent", package: "fluent"),
    .product(name: "Vapor", package: "vapor")
   ]
  ),
  .target(
   name: "Queue",
   dependencies: [
    "Acrylic",
    .product(name: "Fluent", package: "fluent"),
    .product(name: "Vapor", package: "vapor"),
    .product(name: "PostgresKit", package: "postgres-kit"),
    .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
   ]
  ),
  .target(
   name: "Routes",
   dependencies: [
    "Configuration", "Time",
    .product(name: "Fluent", package: "fluent"),
    .product(name: "Vapor", package: "vapor"),
    .product(name: "PostgresKit", package: "postgres-kit"),
    .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
   ]
  ),
  .target(
   name: "Server",
   dependencies: [
    "Databases",
    "Migrations",
    "Encryption",
    "Cache",
    "Models",
    "Queue",
    "Routes"
   ]
  ),
  .executableTarget(name: "Run", dependencies: ["Command", "Time", "Server"]),
  .testTarget(
   name: "ServerTests",
   dependencies: ["Server"]
  ),
 ]
)
