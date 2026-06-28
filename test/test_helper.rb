$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "json"
require "minitest/autorun"
require "net/http"
require "tmpdir"
require "uri"
require "screenshotapi"

class FakeHTTP
  attr_reader :requests
  attr_accessor :use_ssl, :open_timeout, :read_timeout

  def initialize(response = nil, error = nil)
    @response = response
    @error = error
    @requests = []
  end

  def request(request)
    @requests << request
    raise @error if @error

    @response
  end
end

module HTTPResponseHelpers
  def success_response(body: "fake-image", headers: {})
    response = net_response(200, "OK", body: body, response_class: Net::HTTPOK)
    {
      "content-type" => "image/png",
      "x-credits-remaining" => "950",
      "x-screenshot-id" => "ss_test",
      "x-duration-ms" => "1234"
    }.merge(headers).each do |key, value|
      response[key] = value
    end
    response
  end

  def error_response(status, body, message: "Error")
    response_class = Net::HTTPResponse::CODE_TO_OBJ.fetch(status.to_s)
    net_response(status, message, body: body, response_class: response_class)
  end

  def net_response(status, message, body:, response_class:)
    response = response_class.new("1.1", status.to_s, message)
    response.instance_variable_set(:@read, true)
    response.body = body
    response
  end

  def with_fake_http(response = nil, error = nil)
    fake = FakeHTTP.new(response, error)
    calls = []
    factory = lambda do |host, port|
      calls << [host, port]
      fake
    end

    Net::HTTP.stub(:new, factory) do
      yield fake, calls
    end
  end

  def query_hash(request)
    URI.decode_www_form(request.uri.query).to_h
  end
end
