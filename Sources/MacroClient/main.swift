import Macro

@PublicInit
struct A {
    var x: String
    var y: Int
    var z: String
}

let a = A(x: "", y: .zero, z: "")

//struct B {
//    @PublicInit
//    var x: String
//    @PublicInit
//    var b: String
//}
//
//let b = B(x: "", b: "")
