
# Web Dyno Autoscaling

There is one plugin, the New Relic RPM API (define requests per minute that one dyno can handle).
If both plugins are configured, Dynosaur will use the highest estimate and scale your dynos to match.


<pre>
controller_plugins:
    -
        name: dynos
        type: Dynosaur::Controllers::DynosControllerPlugin
        min_resource: <%= ENV.fetch('MIN_WEB_DYNOS', 2) %>
        max_resource: <%= ENV.fetch('MAX_WEB_DYNOS', 15) %>
        input_plugins:
            -
                name: newrelic
                type: Dynosaur::Inputs::NewRelicPlugin
                interval: 10
                key: <%= ENV["NEW_RELIC_API_KEY"] %>
                app_id: 1234567
                rpm_per_dyno: 400
                hysteresis_period: 60
</pre>

## Global Config

- `name` (string): not important, used in Librato metric name so avoid spaces.
- `type: Dynosaur::Controllers::DynosControllerPlugin`
- `min_web_dynos` (int): Never scale below this many dynos
- `max_web_dynos` (int): Never scale above this many dynos


## New Relic plugin

- `key` : The New Relic API key: [Instructions](https://docs.newrelic.com/docs/features/api-key)
- `app_id` : The New Relic App ID (numeric ID, not the name)
- `rpm_per_dyno` : How many requests per minute can one dyno handle?
