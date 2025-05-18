@preconcurrency import Configuration
import Command
import Time
import Server

@main
struct miniServer: AsyncCommand {
 let log: Configuration = .default(
  id: "acrlc.miniServer", informal: "miniServer", formal: "MiniServer"
 ).log()

 var timer = Timer()
 consuming func main() async throws {
  let config = Configuration.default
  timer.fire()

  // MARK: - Boot
  var env: Environment = (try? Environment.detect()) ?? .development
  try LoggingSystem.bootstrap(from: &env)
  let app = try await Application.make(env)

  app.asyncCommands.use(
   .serve { app in
    app.routes.group("test") { route in
     route.get("hello", ":name") { request -> String in
      let name = request.parameters.get("name")!
      return "Hello, \(name)!"
     }

     route.get("user") { request in
      let app = request.application

      let db = app.db
      do {
       let testUserID = UUID(uuidString: "2ED533F8-8829-4099-B028-E8BB5AA1131B")!
       let model: () async throws -> UserModel? = {
        try await db.query(UserModel.self).filter(\.$id == testUserID).first().get()
       }

       if try await model() == nil {
        let testUser = UserModel()
        testUser.id = testUserID
        testUser.name = "testUser"
        testUser.tag = "testUser"
        try! await testUser.save(on: db)
       }
       guard let fetchedModel = try await model() else { fatalError() }
       let testCredentialsID = UUID(uuidString: "8A2C92A7-A138-49D3-837A-3B20AF4DDD43")!
       let credentialsDB = db
       let credentials: () async throws -> UserCredentials? = {
        try await
         credentialsDB.query(UserCredentials.self)
         .filter(\.$id == testCredentialsID)
         .first()
         .get()
       }

       if try await credentials() == nil {
        let testCredentials = UserCredentials()
        testCredentials.id = testCredentialsID
        testCredentials.$model.id = testUserID
        try! await testCredentials.save(on: credentialsDB)
       }

       guard let fetchedCredentials = try await credentials() else { fatalError() }

       return """
       \(fetchedModel.databaseDescription(on: db)) 
       \(fetchedCredentials.databaseDescription(on: db))
       """
      } catch {
       return String(reflecting: error)
      }
     }
    }
   }, as: "serve", isDefault: true
  )

  // MARK: - Configure & Startup
  // MARK: Databases
  for database in DatabaseProtocols.allCases {
   // FIXME: app.logger.logLevel is not modified by serve command
   let logLevel = database.logLevel ?? app.logger.logLevel
   log(
    "Configuring → \(type(of: database)) ⏎ with log level → \(logLevel.name)",
    for: .database
   )
   try database(log, app, logLevel)
  }

  // MARK: Migrations
  for migration in MigrationProtocols.allCases {
   log("Adding → \(type(of: migration))", for: .migration)
   app.migrations.add(migration, to: migration.database?.id)
  }

  log.printConfiguration()
  log("System boot took", timer.elapsed)
  try await app.execute()
 }
}

// MARK: - Configuration
extension Array: Sendable where Element == any DatabaseProtocol {
 nonisolated(unsafe) static let allCases: Self = [.postgres]
}

extension Array where Element == any MigrationProtocol {
 static let allCases: Self = [.user, .userCredentials, .userTokens]
}
