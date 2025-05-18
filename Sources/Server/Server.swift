@_exported import Databases
@_exported import Migrations
@_exported import Encryption
@_exported import Cache
@_exported import Models
@_exported import Queue
@_exported import Routes

// Migrations, Data Mapping
@_exported import Fluent
@_exported import FluentKit

// Server
@_exported import class Vapor.Application
@_exported import struct Vapor.Environment

@preconcurrency import Configuration
import Vapor
import NIOConcurrencyHelpers
/// Boots the application's server. Listens for `SIGINT` and `SIGTERM` for graceful shutdown.
///
///     $ swift run Run serve
///     Server starting on http://localhost:8080
///
public final class ServeCommand: AsyncCommand {
 public struct Signature: CommandSignature, Sendable {
  /// Skip default commands for an environment
  @Option(name: "skip", short: "s") public var skip: String?
  /// - Note: unlike the --log command, this filters levels
  @Option(name: "logLevel", short: "l") var logLevel: Logger.Level?
  /// Force test in any environment, which is useful for validating services
  @Flag(name: "test", short: "t") var forceTest: Bool

  var skipArguments: [Substring]? { skip?.split(separator: ",") }
  var revert: Bool {
   skipArguments?.contains(where: { $0 == "r" || $0 == "revert" }) ?? false == false
  }

  var migrate: Bool {
   skipArguments?.contains(where: { $0 == "m" || $0 == "migrate" }) ?? false == false
  }

  var test: Bool {
   forceTest || skipArguments?.contains(where: { $0 == "t" || $0 == "test" }) ?? false == false
  }

  @Option(name: "hostname", short: "H", help: "Set the hostname the server will run on.")
  var hostname: String?

  @Option(name: "port", short: "p", help: "Set the port the server will run on.")
  var port: Int?

  @Option(name: "bind", short: "b", help: "Convenience for setting hostname and port together.")
  var bind: String?

  @Option(name: "unix-socket", short: nil, help: "Set the path for the unix domain socket file the server will bind to.")
  var socketPath: String?

  public init() {}
 }

 /// Errors that may be thrown when serving a server
 public enum Error: Swift.Error {
  /// Incompatible flags were used together (for instance, specifying a socket path along with a port)
  case incompatibleFlags
 }

 // See `AsyncCommand`.
 public let signature = Signature()

 // See `AsyncCommand`.
 public var help: String {
  return "Begins serving the app over HTTP."
 }

 public let testFunction: (
  @Sendable (Application) async throws -> Void
 )?

 struct SendableBox: @unchecked Sendable {
  var didShutdown: Bool
  var running: Application.Running?
  // FIXME: non-sendable
  var signalSources: [DispatchSourceSignal]
  var server: Server?
 }

 private let box: NIOLockedValueBox<SendableBox>

 /// Create a new `ServeCommand`.
 init(_ testFunction: (@Sendable (Application) async throws -> Void)?) {
  self.testFunction = testFunction
  let box = SendableBox(didShutdown: false, signalSources: [])
  self.box = .init(box)
 }

 // See `AsyncCommand`.
 public func run(using context: CommandContext, signature: Signature) async throws {
  let app = context.application

  if let logLevel = signature.logLevel {
   app.logger.logLevel = logLevel
  }

  let env = app.environment
  let isTestable = env != .production
  let shouldTest = env == .testing || signature.test

  if isTestable {
   let config = Configuration.default

   config("Running default commands", for: env.subject, with: #fileID)

   let revert = signature.revert
   let migrate = signature.migrate
   let envName = env.name.capitalized

   if revert {
    config(
     """
     Reverting \(envName) ⏎ Databases → \
     \(app.databases.ids().map(\.string.localizedUppercase).joined(separator: ","))
     """, for: .migration, with: "revert"
    )

    try await app.autoRevert()
   }

   if revert || migrate || env == .staging { try await app.autoMigrate() }
  }
  
  if let testFunction, isTestable || shouldTest {
   try await testFunction(app)
  }

  switch (signature.hostname, signature.port, signature.bind, signature.socketPath) {
  case (.none, .none, .none, .none): // use defaults
   try await app.server.start(address: nil)

  case let (.none, .none, .none, .some(socketPath)): // unix socket
   try await app.server.start(address: .unixDomainSocket(path: socketPath))

  case let (.none, .none, .some(address), .none): // bind ("hostname:port")
   let hostname = address.split(separator: ":").first.flatMap(String.init)
   let port = address.split(separator: ":").last.flatMap(String.init).flatMap(Int.init)

   try await app.server.start(address: .hostname(hostname, port: port))

  case let (hostname, port, .none, .none): // hostname / port
   try await app.server.start(address: .hostname(hostname, port: port))

  default: throw Error.incompatibleFlags
  }

  var box = self.box.withLockedValue { $0 }
  box.server = app.server

  // allow the server to be stopped or waited for
  let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
  app.running = .start(using: promise)
  box.running = app.running

  // setup signal sources for shutdown
  let signalQueue = DispatchQueue(label: "codes.vapor.server.shutdown")
  func makeSignalSource(_ code: Int32) {
   #if canImport(Darwin)
   /// https://github.com/swift-server/swift-service-lifecycle/blob/main/Sources/UnixSignals/UnixSignalsSequence.swift#L77-L82
   signal(code, SIG_IGN)
   #endif

   let source = DispatchSource.makeSignalSource(signal: code, queue: signalQueue)
   source.setEventHandler {
    print() // clear ^C
    promise.succeed(())
   }
   source.resume()
   box.signalSources.append(source)
  }
  makeSignalSource(SIGTERM)
  makeSignalSource(SIGINT)
  self.box.withLockedValue { $0 = box }
 }

 @available(*, noasync, message: "Use the async asyncShutdown() method instead.")
 func shutdown() {
  var box = self.box.withLockedValue { $0 }
  box.didShutdown = true
  box.running?.stop()
  if let server = box.server {
   server.shutdown()
  }
  box.signalSources.forEach { $0.cancel() } // clear refs
  box.signalSources = []
  self.box.withLockedValue { $0 = box }
 }

 func asyncShutdown() async {
  var box = self.box.withLockedValue { $0 }
  box.didShutdown = true
  box.running?.stop()
  await box.server?.shutdown()
  box.signalSources.forEach { $0.cancel() } // clear refs
  box.signalSources = []
  self.box.withLockedValue { $0 = box }
 }

 deinit {
  assert(self.box.withLockedValue { $0.didShutdown }, "ServeCommand did not shutdown before deinit")
 }
}

public extension AnyAsyncCommand where Self == ServeCommand {
 static func serve(
  _ testFunction: (@Sendable (Application) async throws -> Void)? = nil
 ) -> Self {
  ServeCommand(testFunction)
 }
}
