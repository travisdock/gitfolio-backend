require "graphql/client"
require "graphql/client/http"

# Star Wars API example wrapper
module GitHub
  # Configure GraphQL endpoint using the basic HTTP network adapter.
  HTTP = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
    def headers(context)
      # Optionally set any HTTP headers
      { "Authorization": "token ad310c73e375065bd64c5a1f9e928a7780575c19" }
    end
  end  

  # Fetch latest schema on init, this will make a network request
  Schema = GraphQL::Client.load_schema(HTTP)

  # However, it's smart to dump this to a JSON file and load from disk
  #
  # Run it from a script or rake task
  #   GraphQL::Client.dump_schema(SWAPI::HTTP, "path/to/schema.json")
  #
  # Schema = GraphQL::Client.load_schema("path/to/schema.json")

  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
end

username = 'travisdock'

GitNameQuery = GitHub::Client.parse <<-GRAPHQL
  query {
        repositoryOwner(login: #{username}) {
            # login has to be dynamic
          ... on User {
            pinnedRepositories(first:6) {
              edges {
                node {
                  name
                  url
                  languages(first:10) {
                    edges {
                      node {
                        name
                      }
                    }
                  }
                }
              }
            }
          }
        }
    }
    
GRAPHQL

puts GitNameQuery

result = GitHub::Client.query(GitNameQuery)

data = result.data.repository_owner.pinned_repositories.edges

mapped = data.map do |element| 
    hash = { name: element.node.name, url: element.node.url}
    langs = element.node.languages.edges.map do |lang| 
        lang.node.name
    end.join(", ")
    hash[:languages] = langs
    hash
end

p mapped

# data.each_with_object([]) do |value, result|
#     # data = [node, node, node]
#     binding.pry

#     value.node.name
# end


# '{ "query": "query { repositoryOwner(login: mostlyfocusedmike) { ... on User { pinnedRepositories(first:6) { edges { node { name } } } } } }" }'
