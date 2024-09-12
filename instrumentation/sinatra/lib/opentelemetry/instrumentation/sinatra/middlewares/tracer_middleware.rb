# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'opentelemetry-instrumentation-rack'

module OpenTelemetry
  module Instrumentation
    module Sinatra
      module Middlewares
        # Middleware to trace Sinatra requests
        class TracerMiddleware
          def initialize(app)
            @app = app
          end

          def call(env)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            set_span_name_and_attributes(env, span) if span.recording?
            response = @app.call(env)
            # the following is if we need to set span attributes after the response
            # set_span_name_and_attributes(env, span) unless !span.recording?
            # response
          ensure
            process_response(env, response, span)
          end

          def process_response(env, response, span)
            return unless span.recording?

            sinatra_response = response.nil? ? nil : ::Sinatra::Response.new([], response.first)
            if !sinatra_response.nil? && sinatra_response.server_error?
              span.record_exception(env['sinatra.error']) if env['sinatra.error']
              span.status = OpenTelemetry::Trace::Status.error
            end

            set_span_name_and_attributes(env, span)
          end

          def set_span_name_and_attributes(env, span)
            span.set_attribute('http.route', env['sinatra.route'].split.last) if env['sinatra.route']
            span.name = env['sinatra.route'] if env['sinatra.route']
          end
        end
      end
    end
  end
end
