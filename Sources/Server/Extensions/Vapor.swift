import Chalk

public extension Environment {
 static var staging: Self { .custom(name: "staging") }
}

public extension Environment {
 var color: Color {
  switch self {
  case .staging: .magenta
  case .production: .green
  default: .yellow
  }
 }

 var style: Style {
  switch self {
  case .production: .bold
  default: [.blink, .bold]
  }
 }
 
 var subject: Subject {
  Subject(rawValue: "\(name.capitalized, color: color, style: style)")!
 }
}
