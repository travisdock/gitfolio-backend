class User < ApplicationRecord
  validates :username, presence: true, uniqueness: {case_sensitive: false}
  has_many :repositories


module GitHub
  # Configure GraphQL endpoint using the basic HTTP network adapter.
  HTTP = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
    def headers(context)
      # Optionally set any HTTP headers
      { "Authorization": "token #{ENV["GITHUB_ACCESS_KEY"]}" }
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


  GitNameQuery = GitHub::Client.parse <<-'GRAPHQL'
    query($username: String!) {
          repositoryOwner(login: $username) {
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

  def find_repos()
    result = GitHub::Client.query(GitNameQuery, variables: { username: self.username })

    data = result.data.repository_owner.pinned_repositories.edges

    mapped = data.map do |element|
        hash = { name: element.node.name, url: element.node.url}
        langs = element.node.languages.edges.map do |lang|
            lang.node.name
        end.join(", ")
        hash[:languages] = langs
        hash
    end

    return mapped
  end

  def assign_repos(git_repos)
    git_repos.map do |repo|
      self.repositories.create(repo)
    end
  end


#ALL OUR OTHER SHIT


end
