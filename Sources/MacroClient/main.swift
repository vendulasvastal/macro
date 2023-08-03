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
    let run: () async throws -> Void
}
