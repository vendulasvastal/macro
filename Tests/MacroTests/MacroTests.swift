import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import MacroMacros

let testMacros: [String: Macro.Type] = [
    "URL": URLMacro.self,
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
}
