import Acrylic
import Time

struct TimerModule: Module {
 @Context var timer: any TimerProtocol
 @Modular var handler: (any TimerProtocol) throws -> Modules
 init(
  with timer: any TimerProtocol = .standard,
  @Modular handler: @escaping (any TimerProtocol) throws -> Modules
 ) {
  self.timer = timer
  self.handler = handler
 }

 var void: some Module {
  get throws {
   try withTimer(timer) {
    try self.handler($0)
   }
  }
 }
}

extension Module {
 typealias Timer = TimerModule
}
