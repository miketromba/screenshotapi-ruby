require "net/http"
require "uri"
require "json"

module ScreenshotAPI
  class Client
    QUERY_PARAM_MAP = {
      url: "url",
      width: "width",
      height: "height",
      full_page: "fullPage",
      type: "type",
      quality: "quality",
      color_scheme: "colorScheme",
      wait_until: "waitUntil",
      wait_for_selector: "waitForSelector",
      delay: "delay",
      block_ads: "blockAds",
      remove_cookie_banners: "removeCookieBanners",
      css_inject: "cssInject",
      js_inject: "jsInject",
      stealth_mode: "stealthMode",
      device_pixel_ratio: "devicePixelRatio",
      timezone: "timezone",
      locale: "locale",
      cache_ttl: "cacheTtl",
      preload_fonts: "preloadFonts",
      remove_elements: "removeElements",
      remove_popups: "removePopups",
      mockup_device: "mockupDevice",
      geo_latitude: "geoLatitude",
      geo_longitude: "geoLongitude",
      geo_accuracy: "geoAccuracy"
    }.freeze

    BODY_PARAM_MAP = QUERY_PARAM_MAP.merge(
      html: "html",
      geo_location: "geoLocation"
    ).freeze

    def initialize(api_key, base_url: DEFAULT_BASE_URL, timeout: DEFAULT_TIMEOUT)
      raise ArgumentError, "API key is required" if blank?(api_key)

      @api_key = api_key.to_s
      @base_url = normalize_base_url(base_url)
      @timeout = timeout
    end

    def screenshot(**options)
      validate_capture_target!(options)

      uri, request = build_request(options)
      request["x-api-key"] = @api_key

      response = perform_request(uri, request)

      unless response.is_a?(Net::HTTPSuccess)
        handle_error(response)
      end

      metadata = Metadata.new(
        credits_remaining: integer_header(response, "x-credits-remaining"),
        screenshot_id: response["x-screenshot-id"] || "",
        duration_ms: integer_header(response, "x-duration-ms")
      )

      Result.new(
        image: response.body,
        content_type: response["content-type"] || "image/png",
        metadata: metadata
      )
    end

    def save(path:, **options)
      result = screenshot(**options)
      File.binwrite(path, result.image)
      result.metadata
    end

    private

    def perform_request(uri, request)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @timeout
      http.read_timeout = @timeout

      http.request(request)
    rescue Timeout::Error, SocketError, SystemCallError, IOError => e
      raise NetworkError, e.message
    end

    def build_uri(options)
      params = build_params(options, QUERY_PARAM_MAP)

      uri = URI("#{@base_url}/api/v1/screenshot")
      uri.query = URI.encode_www_form(params)
      uri
    end

    def build_request(options)
      if present?(options[:html])
        uri = URI("#{@base_url}/api/v1/screenshot")
        request = Net::HTTP::Post.new(uri)
        request["content-type"] = "application/json"
        request.body = JSON.generate(build_body(options))
        [uri, request]
      else
        uri = build_uri(options)
        [uri, Net::HTTP::Get.new(uri)]
      end
    end

    def build_body(options)
      build_params(options, BODY_PARAM_MAP, stringify: false)
    end

    def build_params(options, mapping, stringify: true)
      mapping.each_with_object({}) do |(option_key, param_key), params|
        next unless options.key?(option_key)

        value = normalize_param_value(option_key, options[option_key], stringify: stringify)
        next if value.nil?

        params[param_key] = stringify ? value.to_s : value
      end
    end

    def normalize_param_value(option_key, value, stringify:)
      return nil if value.nil?
      return value.join(",") if stringify && option_key == :remove_elements && value.respond_to?(:join)

      value
    end

    def handle_error(response)
      body = parse_error_body(response)

      message = body["error"] || body["message"] || "HTTP #{response.code}"

      case response.code.to_i
      when 401
        raise AuthenticationError, message
      when 402
        balance = body.key?("balance") ? body["balance"] : body["creditBalance"]
        raise InsufficientCreditsError.new(message, balance: integer_value(balance))
      when 403
        raise InvalidAPIKeyError, message
      when 500
        raise ScreenshotFailedError, (body["message"] || body["error"] || "Screenshot failed")
      else
        raise APIError.new(message, status: response.code.to_i, code: "unknown_error")
      end
    end

    def parse_error_body(response)
      parsed = JSON.parse(response.body.to_s)
      parsed.is_a?(Hash) ? parsed : { "error" => "HTTP #{response.code}" }
    rescue JSON::ParserError
      { "error" => "HTTP #{response.code}" }
    end

    def integer_header(response, header)
      integer_value(response[header])
    end

    def integer_value(value)
      return 0 if value.nil? || value.to_s.empty?

      value.to_i
    end

    def validate_capture_target!(options)
      return if present?(options[:html])
      return if present?(options[:url])

      raise ArgumentError, "URL or HTML is required"
    end

    def normalize_base_url(base_url)
      value = base_url.to_s.strip
      raise ArgumentError, "base_url is required" if value.empty?

      value.sub(%r{/+\z}, "")
    end

    def blank?(value)
      !present?(value)
    end

    def present?(value)
      !value.nil? && !value.to_s.strip.empty?
    end
  end
end
