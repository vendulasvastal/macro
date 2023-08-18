import Macro

@PublicInit
struct A {
    var x: String
    var y: Int
    var z: String
}

let a = A(x: "", y: .zero, z: "")

typealias HO = () -> Void

@PublicInit
struct B {
    let run: @Sendable () async throws -> Void
}

@PublicInit
struct C {
    var title: String = ""
    var count: Int = 0
    var greeting: String = "ahoj"
}
