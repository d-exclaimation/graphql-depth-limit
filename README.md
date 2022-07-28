# GraphQL Depth Limit

Dead-simple defense against unbounded GraphQL queries. Limit the complexity of the queries solely by their _depth_.

Implementation of [GraphQL Depth Limit](https://github.com/ashfurrow/graphql-depth-limit) for [GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL)

## Why?

Suppose you have an `User` type that has a list of `Item`s.

```graphql
type User {
  id: Int!
  items: [Item!]!
}

type Item {
  id: Int!
  label: String!
  owner: User!
}
```

and you would normally expect query that look something like:

```graphql
{
  user(id: 10) {
    id
    items {
      label
    }
  }
}
```

Given that the `Item` allow you to get back up to `User`, that opens your server to the possibility of a cyclical query!

```graphql
query Evil {
  user(id: 10) {
    items {
      owner {
        items {
          owner {
            items {
              owner {
                items {
                  owner {
                    items {
                      owner {
                        items {
                          owner {
                            items {
                              owner {
                                # and so on...
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

This will likely become a very expensive operation, at some point pinning a CPU on the server or perhaps the database, which opens up the possiblility of DOS attacks. Therefore, you might want a way to validate the complexity of incoming queries.

This implementation lets you limit the total depth of each operation.

## Usage

Add this package to your `Package.swift`

```swift
.package(url: "https://github.com/d-exclaimation/graphql-depth-limit", from: "0.1.0")
```

It works without any additional libraries outside [GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL)

**Usage without additional libraries**

```swift
import GraphQL
import GraphQLDepthLimit

let query: String = "..."
let ast = try parse(source: .init(body: query))
try await graphql(validationRules: [depthLimit(ast, max: 10)], schema: schema, request: query, eventLoopGroup: eventLoopGroup).get()
```

**Usage with [Pioneer](https://github.com/d-exclaimation/pioneer)**

```swift
import Vapor
import Pioneer
import GraphQLDepthLimit

let app = try Application(.detect())
let server = Pioneer(
    schema: schema,
    resolver: resolver,
    contextBuilder: { req, res in

    },
    validationRules: .computed({ gql in
        [depthLimit(gql.ast, max: 10)]
    })
)

server.applyMiddleware(on: app)
```

Now the query above should result in an error response:

```json
{
  "errors": [
    {
      "message": "Operation 'Evil' exceeds maximum operation depth of 10",
      "locations": [
        {
          "line": 12,
          "column": 25
        }
      ]
    }
  ]
}
```
