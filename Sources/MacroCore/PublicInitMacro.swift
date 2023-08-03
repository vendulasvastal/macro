import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct PublicInitMacro: MemberMacro {
    enum Errors: Swift.Error, CustomStringConvertible {
        case invalidInputType

        var description: String {
            "@PublicInit is only applicable to structs or classes"
        }
    }

    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard declaration.is(ClassDeclSyntax.self) || declaration.is(StructDeclSyntax.self) else {
            throw Errors.invalidInputType
        }
        
        let members = declaration.memberBlock.members
        let storedProperties = members.storedProperties
        
        let arguments = storedProperties.compactMap { syntax -> (name: String, type: String, initializer: String?)? in
            guard let patternBinding = syntax.bindings.first else { return nil }
            
            // is let and has initializer -> cannot be initialized again
            if syntax.bindingKeyword.tokenKind == .keyword(.let), patternBinding.initializer != nil { return nil }
            guard let name = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { return nil }
            guard let type = patternBinding.typeAnnotation?.type else { return nil }
            var typeSourceString = Syntax(type).source()
        
            if patternBinding.typeAnnotation?.type.isFunctionType == true {
                typeSourceString = "@escaping " + typeSourceString
            }
            
            let initializerExprString = patternBinding.initializer.map { Syntax($0.value) }?.source()
            
            return (name: name, type: typeSourceString, initializer: initializerExprString)
        }

        let initBody: ExprSyntax = """
            \(raw: arguments.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n\t"))
        """

        let initDeclSyntax = try InitializerDeclSyntax(
            PartialSyntaxNodeString(
                stringLiteral: """
                public init(
                \(arguments.map { "\($0.name): \($0.type)" + ($0.initializer.map { "= \($0)" } ?? "") }.joined(separator: ",\n"))
                )
                """
            ),
            bodyBuilder: {
                initBody
            }
        )

        let finalDeclaration = DeclSyntax(initDeclSyntax)

        return [finalDeclaration]
    }
}

extension TypeSyntax {
    var isFunctionType: Bool {
        self.is(FunctionTypeSyntax.self) || self.as(AttributedTypeSyntax.self)?.baseType.isFunctionType == true
    }
}

extension VariableDeclSyntax {
    /// Check if this variable has the syntax of a stored property.
    var isStoredProperty: Bool {
        guard let binding = bindings.first,
              bindings.count == 1,
              !isLazyProperty,
              !isConstant else {
            return false
        }

        switch binding.accessor {
        case .none:
            return true
        case .accessors(let node):
            // traverse accessors
            for accessor in node.accessors {
                switch accessor.accessorKind.tokenKind {
                case .keyword(.willSet), .keyword(.didSet):
                    // stored properties can have observers
                    break
                default:
                    // everything else makes it a computed property
                    return false
                }
            }
            return true
        case .getter:
            return false
        }
    }

    var isLazyProperty: Bool {
        modifiers?.contains { $0.name.tokenKind == .keyword(Keyword.lazy) } ?? false
    }

    var isConstant: Bool {
        bindingKeyword.tokenKind == .keyword(.let) && bindings.first?.initializer != nil
    }
}

extension MemberDeclListSyntax {
    var storedProperties: [VariableDeclSyntax] {
        compactMap {
            if let variable = $0.decl.as(VariableDeclSyntax.self), variable.isStoredProperty {
                return variable
            } else { return nil }
        }
    }
}

extension Syntax {
    public func source() -> String {
        var result = ""
        write(to: &result)
        return result
    }
}
