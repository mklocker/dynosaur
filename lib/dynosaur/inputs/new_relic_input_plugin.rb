require 'dynosaur/new_relic_api_client'
require 'dynosaur/version'
require 'dynosaur/error_handler'

# ScalerPlugin implementation that uses the New Relic API
# to get the current requests per minute on the site, and scale to an
# appropriate number of dynos.

module Dynosaur
  module Inputs
    class NewRelicInputPlugin < AbstractInputPlugin

      DEFAULT_RPM_PER_DYNO = 150

      # Load config from the config hash
      def initialize(config)
        super

        @unit = "RPM"
        @key = config["key"]
        @app_id = config["app_id"].to_s
        @rpm_per_dyno = config.fetch("rpm_per_dyno", DEFAULT_RPM_PER_DYNO).to_i

        if @hysteresis_period < 60
          raise "The hysteresis_period must be longer than 60s for New Relic"
        end

        if @key.blank?
          raise "You must supply API key in the new relic plugin config"
        end
        if @app_id.blank?
          raise "You must supply app_id in the new relic plugin config"
        end

        @metric_name = "HttpDispatcher"
        @new_relic_api_client = Dynosaur::NewRelicApiClient.new(@key, @app_id)
      end

      def retrieve
        return get_rpm
      end

      def value_to_resources(rpm)
        return -1 if rpm.nil?
        dynos_to_scale_to = (rpm / @rpm_per_dyno.to_f).ceil
        puts "Dynosaur - Auto Scaling: RPM = #{rpm}. RPM per dyno: #{@rpm_per_dyno}. Recommended Dynos: #{dynos_to_scale_to}"
        return dynos_to_scale_to
      end

      private

      def get_rpm
        begin
          # New Relic is not very accurate and sometimes returns data for the
          # current minute, as if it was already complete.
          # This is not an issue here because we always use the max value from
          # the ring buffer. This would become an issue if we had an
          # hysteresis_period smaller than 1 minute.
          rpm = @new_relic_api_client.get_metric(@metric_name,
                                                  value_name: 'call_count',
                                                  summarize: false)
          return rpm
        rescue StandardError => e
          Dynosaur::ErrorHandler.handle(e)
          puts "Dynosaur - Auto Scaling: ERROR: failed to decipher New Relic result"
          puts e.inspect
        end
      end
    end
  end
end
