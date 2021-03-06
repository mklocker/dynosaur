require 'dynosaur/new_relic_api_client'
require 'time'

module Dynosaur
  module Inputs
    class RediscloudConnectionUsageInputPlugin < AbstractInputPlugin

      def initialize(config)
        super(config)
        @unit = "number of active connections"
        @max_percentage_threshold = config.fetch('max_percentage_threshold', 90.0).to_f
        @metric_name = "Component/redis/Connections[connections]"

        # Get the list at https://api.newrelic.com/v2/components.json
        component_id = config['component_id'] # Some internal New Relic id
        @new_relic_api_client = Dynosaur::NewRelicApiClient.new(config['new_relic_api_key'], component_id)
      end

      def retrieve
        return get_number_of_connections
      end

      def value_to_resources(value)
        return suitable_plans(value).first
      end

      private

      def get_number_of_connections
        return @new_relic_api_client.get_metric(@metric_name)
      end


      def suitable_plans(value)
        return plans.select{ |plan|
          plan['max_connections'].nil? || (plan["max_connections"] * (@max_percentage_threshold / 100) > value)
        }.sort_by{ |plan|
          # Order by memory as expensive plans don't have a connections value
          plan['max_memory']
        }
      end

      def plans
        Dynosaur::Addons.plans_for_addon('rediscloud')
      end

    end
  end # Inputs
end # Dynosaur
