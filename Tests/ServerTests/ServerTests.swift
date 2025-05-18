@testable import Server
import Testing

struct miniServerTests {
 @Test
 func testShutdown() async throws {
  var env: Environment = try Environment.detect()
  try LoggingSystem.bootstrap(from: &env)
  let app = try await Application.make(env)
  app.logger.logLevel = .debug
  try await app.asyncBoot()
  try await app.asyncShutdown()
 }
}
