//
//  DepthLimit.swift
//
//  Created by d-exclaimation.
//

import Foundation
import GraphQL

/// Use the depth limit validation rules
/// - Parameters:
///   - max: The maximum depth
///   - ignoring: The rule to ignore certain field
/// - Returns: A validation rule for validating depth limit
public func depthLimit(_ ast: Document?, max: Int, ignoring: DepthLimit.Ignore = .none) -> (ValidationContext) -> Visitor {
    // return DepthLimit(maxDepth: max, ignoring: ignoring).validationRule
    return { context in
        DepthLimit(context: context, maxDepth: max, ignoring: ignoring).validate(ast)
    }
}

/// GraphQL Query Depth Limit Validation Rule
public struct DepthLimit {
    /// A rule to ignore calculation on certain field name
    public enum Ignore {
        /// Exactly match a string
        case exact(String)
        /// Matches a regex pattern
        case regex(String)
        /// Matches from a function
        case function((String) -> Bool)
        /// No ignoring any field
        case none
    }

    private let maxDepth: Int
    private let ignoring: Ignore
    private let context: ValidationContext

    /// Create a new Depth Limit rule
    /// - Parameters:
    ///   - context: ValidationContext to report and error
    ///   - maxDepth: Maximum field depth (inclusive)
    ///   - ignoring: Ignoring field rule
    public init(context: ValidationContext, maxDepth: Int, ignoring: Ignore = .none) {
        self.maxDepth = maxDepth
        self.ignoring = ignoring
        self.context = context
    }

    
    /// Validate whether a GraphQLRequest follow the depth limit rule
    /// - Parameter gql: The GraphQL Request being made
    public func validate(_ ast: Document?) -> Visitor {
        guard let definitions = ast?.definitions else {
            return .init()
        }
        let fragments = getFragments(from: definitions)
        let queries = getQueriesAndMutations(from: definitions)
        for query in queries {
            self.depth(query.value, fragments: fragments, operationName: query.key) 
        }
        return .init()
    }
    
    private func depth(_ node: Node, fragments:  [String: FragmentDefinition], operationName: String, depthSoFar: Int = 0) {
        if depthSoFar > maxDepth {
            context.report(error: .init(message: "Operation '\(operationName)' exceeds maximum operation depth of \(maxDepth)", nodes: [node]))
            return
        }
        switch (node) {
        case let field as Field:
            // by default, ignore the introspection fields which begin with double underscores
            if !shouldIgnore(field: field), let selectionSet = field.selectionSet {
                for selection in selectionSet.selections {
                    depth(selection, fragments: fragments, operationName: operationName, depthSoFar: depthSoFar + 1)
                }
            }
        case let spread as FragmentSpread:
            guard let fragment = fragments[spread.name.value] else { break }
            depth(fragment, fragments: fragments, operationName: operationName, depthSoFar: depthSoFar)
        case let inline as InlineFragment:
            for selection in inline.selectionSet.selections {
                depth(selection, fragments: fragments, operationName: operationName, depthSoFar: depthSoFar)
            }
        case let fragment as FragmentDefinition:
            for selection in fragment.selectionSet.selections {
                depth(selection, fragments: fragments, operationName: operationName, depthSoFar: depthSoFar)
            }
        case let operation as OperationDefinition:
            for selection in operation.selectionSet.selections {
                depth(selection, fragments: fragments, operationName: operationName, depthSoFar: depthSoFar)
            }
        default:
            break
        }
    }

    private func shouldIgnore(field: Field) -> Bool {
        guard !isIntrospection(field: field) else {
            return true
        }
        let fieldName = field.name.value
        switch ignoring {
        case .exact(let match):
            return fieldName == match
        case .regex(let pattern):
            guard let res = try? NSRegularExpression(pattern: pattern)
                .matches(in: fieldName, range: .init(location: 0, length: fieldName.count)) else {
                return false
            }
            return res.count > 0
        case .function(let rule):
            return rule(fieldName)
        case .none:
            return false
        }
    }

    private func isIntrospection(field: Field) -> Bool {
        guard let res = try? NSRegularExpression(pattern: "^__")
            .matches(in: field.name.value, range: .init(location: 0, length: field.name.value.count)) else {
            return false
        }
        return res.count > 0
    }
}

private func getFragments(from definitions: [Definition]) -> [String: FragmentDefinition] {
    definitions.reduce([String: FragmentDefinition]()) { (map, definition) in
        if let fragement =  definition as? FragmentDefinition {
            return map.merging([fragement.name.value: fragement]) { $1 }
        }
        return map
    }
}

private func getQueriesAndMutations(from definitions: [Definition]) -> [String: OperationDefinition] {
    definitions.reduce([String: OperationDefinition]()) { (map, definition) in
        if let operation = definition as? OperationDefinition {
            return map.merging([operation.name?.value ?? "": operation]) { $1 }
        }
        return map
    }
}