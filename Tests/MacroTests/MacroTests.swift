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
}
