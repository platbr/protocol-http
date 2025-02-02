# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative 'body/buffered'
require_relative 'body/reader'

module Protocol
	module HTTP
		# Represents an HTTP response which can be used both server and client-side.
		#
		# ~~~ ruby
		# require 'protocol/http'
		# 
		# # Long form:
		# Protocol::HTTP::Response.new("http/1.1", 200, Protocol::HTTP::Headers[["content-type", "text/html"]], Protocol::HTTP::Body::Buffered.wrap("Hello, World!"))
		# 
		# # Short form:
		# Protocol::HTTP::Response[200, {"content-type" => "text/html"}, ["Hello, World!"]]
		# ~~~
		class Response
			prepend Body::Reader
			
			# Create a new response.
			#
			# @parameter version [String | Nil] The HTTP version, e.g. `"HTTP/1.1"`. If `nil`, the version may be provided by the server sending the response.
			# @parameter status [Integer] The HTTP status code, e.g. `200`, `404`, etc.
			# @parameter headers [Hash] The headers, e.g. `{"content-type" => "text/html"}`, etc.
			# @parameter body [Body::Readable] The body, e.g. `"Hello, World!"`, etc.
			# @parameter protocol [String | Array(String)] The protocol, e.g. `"websocket"`, etc.
			def initialize(version = nil, status = 200, headers = Headers.new, body = nil, protocol = nil)
				@version = version
				@status = status
				@headers = headers
				@body = body
				@protocol = protocol
			end
			
			# @attribute [String | Nil] The HTTP version, usually one of `"HTTP/1.1"`, `"HTTP/2"`, etc.
			attr_accessor :version
			
			# @attribute [Integer] The HTTP status code, e.g. `200`, `404`, etc.
			attr_accessor :status
			
			# @attribute [Hash] The headers, e.g. `{"content-type" => "text/html"}`, etc.
			attr_accessor :headers
			
			# @attribute [Body::Readable] The body, e.g. `"Hello, World!"`, etc.
			attr_accessor :body
			
			# @attribute [String | Array(String) | Nil] The protocol, e.g. `"websocket"`, etc.
			attr_accessor :protocol
			
			# Whether the response is considered a hijack: the connection has been taken over by the application and the server should not send any more data.
			def hijack?
				false
			end
			
			# Whether the status is 100 (continue).
			def continue?
				@status == 100
			end
			
			# Whether the status is considered informational.
			def informational?
				@status and @status >= 100 && @status < 200
			end
			
			# Whether the status is considered final. Note that 101 is considered final.
			def final?
				# 101 is effectively a final status.
				@status and @status >= 200 || @status == 101
			end
			
			# Whether the status is 200 (ok).
			def ok?
				@status == 200
			end
			
			# Whether the status is considered successful.
			def success?
				@status and @status >= 200 && @status < 300
			end
			
			# Whether the status is 206 (partial content).
			def partial?
				@status == 206
			end
			
			# Whether the status is considered a redirection.
			def redirection?
				@status and @status >= 300 && @status < 400
			end
			
			# Whether the status is 304 (not modified).
			def not_modified?
				@status == 304
			end
			
			# Whether the status is 307 (temporary redirect) and should preserve the method of the request when following the redirect.
			def preserve_method?
				@status == 307 || @status == 308
			end
			
			# Whether the status is considered a failure.
			def failure?
				@status and @status >= 400 && @status < 600
			end
			
			# Whether the status is 400 (bad request).
			def bad_request?
				@status == 400
			end
			
			# Whether the status is 500 (internal server error).
			def internal_server_error?
				@status == 500
			end
			
			# @deprecated Use {#internal_server_error?} instead.
			alias server_failure? internal_server_error?
			
			# A short-cut method which exposes the main response variables that you'd typically care about. It follows the same order as the `Rack` response tuple, but also includes the protocol.
			#
			# ~~~ ruby
			# 	Response[200, {"content-type" => "text/html"}, ["Hello, World!"]]
			# ~~~
			#
			# @parameter status [Integer] The HTTP status code, e.g. `200`, `404`, etc.
			# @parameter headers [Hash] The headers, e.g. `{"content-type" => "text/html"}`, etc.
			# @parameter body [String | Array(String) | Body::Readable] The body, e.g. `"Hello, World!"`, etc. See {Body::Buffered.wrap} for more information about .
			def self.[](status, _headers = nil, _body = nil, headers: _headers, body: _body, protocol: nil)
				body = Body::Buffered.wrap(body)
				headers = Headers[headers]
				
				self.new(nil, status, headers, body, protocol)
			end
			
			# Create a response for the given exception.
			#
			# @parameter exception [Exception] The exception to generate the response for.
			def self.for_exception(exception)
				Response[500, Headers['content-type' => 'text/plain'], ["#{exception.class}: #{exception.message}"]]
			end
			
			def as_json(...)
				{
					version: @version,
					status: @status,
					headers: @headers&.as_json,
					body: @body&.as_json,
					protocol: @protocol
				}
			end
			
			def to_json(...)
				as_json.to_json(...)
			end
			
			def to_s
				"#{@status} #{@version}"
			end
			
			def to_ary
				return @status, @headers, @body
			end
		end
	end
end
