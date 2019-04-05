require 'graphql'

class GenericFunction < GraphQL::Function
  attr_reader :type

  def initialize(model_class:, type:)
    @model_class = model_class
    @type = type
  end

  def call(_obj, _args, _ctx)
    @model_class.dataset
  rescue StandardError => e
    pp e
    raise GraphQL::ExecutionError, 'Something went wrong!'
  end
end

# We use Sequel::Model in our project
class FakeModel
  def self.dataset
    []
  end
end

class BaseObject < GraphQL::Schema::Object; end

class Currency < BaseObject
  field :value, String, null: false
end

class RootQuery < BaseObject
  field :currency_list, function: GenericFunction.new(
    model_class: FakeModel,
    type: Currency.connection_type.to_non_null_type
  )
end


class GraphqlSchema < GraphQL::Schema
  query RootQuery
end

query = <<~GRAPHQL
  query {
    currencyList {
      edges {
        cursor
        node {
          value
        }
      }
    }
  }
GRAPHQL

pp GraphqlSchema.execute(
  query,
  variables: {},
  context: nil,
)
