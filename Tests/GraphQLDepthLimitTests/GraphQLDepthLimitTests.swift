import XCTest
import GraphQL
@testable import GraphQLDepthLimit

final class GraphQLDepthLimitTests: XCTestCase {
    struct Object {}

    static func makeSchema() throws -> GraphQLSchema {
        let object5 = try GraphQLObjectType(
            name: "Object5", fields: [
                "end": GraphQLField(
                    type: GraphQLInt, 
                    resolve: { _, _, _, _ in
                        return 0
                    }
                )
            ]
        )
        let object4 = try GraphQLObjectType(
            name: "Object4", fields: [
                "field5": GraphQLField(
                    type: object5,
                    resolve: { _, _, _, _ in
                        return Object()
                    }
                ),
                "end": GraphQLField(
                    type: GraphQLInt, 
                    resolve: { _, _, _, _ in
                        return 0
                    }
                )
            ]
        )
        let object3 = try GraphQLObjectType(
            name: "Object3", fields: [
                "field4": GraphQLField(
                    type: object4,
                    resolve: { _, _, _, _ in
                        return Object()
                    }
                ),
                "end": GraphQLField(
                    type: GraphQLInt, 
                    resolve: { _, _, _, _ in
                        return 0
                    }
                )
            ]
        )
        let object2 = try GraphQLObjectType(
            name: "Object2", fields: [
                "field3": GraphQLField(
                    type: object3,
                    resolve: { _, _, _, _ in
                        return Object()
                    }
                ),
                "end": GraphQLField(
                    type: GraphQLInt, 
                    resolve: { _, _, _, _ in
                        return 0
                    }
                )
            ]
        )
        let object1 = try GraphQLObjectType(
            name: "Object1", fields: [
                "field2": GraphQLField(
                    type: object2,
                    resolve: { _, _, _, _ in
                        return Object()
                    }
                ),
                "end": GraphQLField(
                    type: GraphQLInt, 
                    resolve: { _, _, _, _ in
                        return 0
                    }
                )
            ]
        )
        let object0 = try GraphQLObjectType(
            name: "Object0", fields: [
                "field1": GraphQLField(
                    type: object1,
                    resolve: { _, _, _, _ in
                        return Object()
                    }
                ),
                "end": GraphQLField(
                    type: GraphQLInt, 
                    resolve: { _, _, _, _ in
                        return 0
                    }
                )
            ]
        )
    
        return try .init(
            query: .init(
                name: "RootQueryType", 
                fields: [
                    "field0": GraphQLField(
                        type: object0,
                        resolve: { _, _, _, _ in
                            return Object()   
                        }
                    )
                ]
            )
        )
    }
    private let schema: GraphQLSchema = try! makeSchema()

    func testValidQuery() throws {
        let query = """
        query Valid {
            field0 {
                field1 {
                    field2 {
                        end
                    }
                }
            }
        }
        """

        let source = Source(body: query)
        let ast = try parse(source: source)
        let rule = depthLimit(ast, max: 5)
        let errors = validate(schema: schema, ast: ast, rules: [rule])

        XCTAssert(errors.isEmpty)
    }

    func testInvalidQuery() throws {
        let query = """
        query Valid {
            field0 {
                field1 {
                    field2 {
                        field3 {
                            field4 {
                                field5 {
                                    end
                                }
                            }
                        }
                    }
                }
            }
        }
        """

        let source = Source(body: query)
        let ast = try parse(source: source)
        let rule = depthLimit(ast, max: 2)
        let errors = validate(schema: schema, ast: ast, rules: [rule])

        XCTAssertFalse(errors.isEmpty)
        XCTAssertEqual("Operation 'Valid' exceeds maximum operation depth of 2", errors.first?.message)
    }

    func testIgnoring() throws {
        let query = """
        query Valid {
            field0 {
                field1 {
                    field2 {
                        field3 {
                            field4 {
                                field5 {
                                    end
                                }
                            }
                        }
                    }
                }
            }
        }
        """

        let source = Source(body: query)
        let ast = try parse(source: source)
        let rule = depthLimit(ast, max: 2, ignoring: .exact("field1"))
        let errors = validate(schema: schema, ast: ast, rules: [rule])

        XCTAssert(errors.isEmpty)
    }

    func testIntrospection() throws {
        let query = """
        query IntrospectionQuery {
          __schema {
            queryType {
              name
            }
            mutationType {
              name
            }
            subscriptionType {
              name
            }
            types {
              ...FullType
            }
            directives {
              name
              description
        
              locations
              args {
                ...InputValue
              }
            }
          }
        }
        
        fragment FullType on __Type {
            kind
            name
            description
        
            fields(includeDeprecated: true) {
                name
                description
                args {
                    ...InputValue
                }
                type {
                    ...TypeRef
                }
                isDeprecated
                deprecationReason
            }
            inputFields {
                ...InputValue
            }
            interfaces {
                ...TypeRef
            }
            enumValues(includeDeprecated: true) {
                name
                description
                isDeprecated
                deprecationReason
            }
            possibleTypes {
                ...TypeRef
            }
        }
        
        fragment InputValue on __InputValue {
            name
            description
            type {
                ...TypeRef
            }
            defaultValue
        }
        
        fragment TypeRef on __Type {
            kind
            name
            ofType {
                kind
                name
                ofType {
                    kind
                    name
                    ofType {
                        kind
                        name
                        ofType {
                            kind
                            name
                            ofType {
                                kind
                                name
                                ofType {
                                    kind
                                    name
                                    ofType {
                                        kind
                                        name
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        """

        let source = Source(body: query)
        let ast = try parse(source: source)
        let rule = depthLimit(ast, max: 0, ignoring: .exact("end"))
        let errors = validate(schema: schema, ast: ast, rules: [rule])

        XCTAssert(errors.isEmpty)
    }

    func testBlockEverything() throws {
        let query = """
        query Valid {
            field0 {
                end
            }
        }
        """

        let source = Source(body: query)
        let ast = try parse(source: source)
        let rule = depthLimit(ast, max: 1)
        let errors = validate(schema: schema, ast: ast, rules: [rule])

        XCTAssertTrue(errors.isEmpty)
    }
}
