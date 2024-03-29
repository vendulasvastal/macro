import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import MacroCore

let testMacros: [String: Macro.Type] = [
    "URL": URLMacro.self,
    "PublicInit": PublicInitMacro.self
]

final class MacroTests: XCTestCase {
    func testValidURL() {
        assertMacroExpansion(
            #"""
            #URL("https://www.avanderlee.com")
            """#,
            expandedSource: #"""
            URL(string: "https://www.avanderlee.com")!
            """#,
            macros: testMacros
        )
    }

    func testURLStringLiteralError() {
        assertMacroExpansion(
            #"""
            #URL("https://www.avanderlee.com/\(Int.random())")
            """#,
            expandedSource: #"""

            """#,
            diagnostics: [
                DiagnosticSpec(message: "#URL requires a static string literal", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    func testStructPublicInit() {
        assertMacroExpansion(
            #"""
            @PublicInit
            struct A {
                var x: String
                var y: Int
                var z: String
            }
            """#,
            expandedSource: #"""
            struct A {
                var x: String
                var y: Int
                var z: String
            
                public init(
                    x: String,
                    y: Int,
                    z: String
                ) {
                    self.x = x
                    self.y = y
                    self.z = z
                }
            }
            """#,
            macros: testMacros
        )
    }
    
    func testPublicInitWithClosureProperty() {
        assertMacroExpansion(
            #"""
            @PublicInit
            struct B {
                let run: () async throws -> Void
            }
            """#
            , expandedSource: #"""
            struct B {
                let run: () async throws -> Void
            
                public init(
                    run: @escaping () async throws -> Void
                ) {
                    self.run = run
                }
            }
            """#,
            macros: testMacros
        )
    }
    
    func testPublicInitWithSendableClosureProperty() {
        assertMacroExpansion(
            #"""
            @PublicInit
            struct B {
                let run: @Sendable () async throws -> Void
            }
            """#
            , expandedSource: #"""
            struct B {
                let run: @Sendable () async throws -> Void
            
                public init(
                    run: @escaping @Sendable () async throws -> Void
                ) {
                    self.run = run
                }
            }
            """#,
            macros: testMacros
        )
    }
    
    func testPublicInitWithVariablePropertyWrapper() {
        assertMacroExpansion(
            #"""
            @PublicInit
            struct B {
                @State var title: String = ""
            }
            """#
            , expandedSource: #"""
            struct B {
                @State var title: String = ""
            
                public init(
                    title: String = ""
                ) {
                    self.title = title
                }
            }
            """#,
            macros: testMacros
        )
    }
    
    func testPublicInitWithInitialValues() {
        assertMacroExpansion(
            #"""
            @PublicInit
            struct B {
                var title: String = ""
                var count: Int = 0
                var greeting: String = "ahoj"
            }
            """#
            , expandedSource: #"""
            struct B {
                var title: String = ""
                var count: Int = 0
                var greeting: String = "ahoj"
            
                public init(
                    title: String = "",
                    count: Int = 0,
                    greeting: String = "ahoj"
                ) {
                    self.title = title
                    self.count = count
                    self.greeting = greeting
                }
            }
            """#,
            macros: testMacros
        )
    }
}
