require_relative "test_helper"

class ClientTest < Minitest::Test
  include HTTPResponseHelpers

  TEST_KEY = "sk_test_abc123"

  def test_constructor_requires_api_key
    assert_raises(ArgumentError) { ScreenshotAPI::Client.new(nil) }
    assert_raises(ArgumentError) { ScreenshotAPI::Client.new("") }
    assert_raises(ArgumentError) { ScreenshotAPI::Client.new("   ") }
  end

  def test_strips_all_trailing_slashes_from_base_url
    with_fake_http(success_response) do |fake, calls|
      client = ScreenshotAPI::Client.new(TEST_KEY, base_url: "https://proxy.example///")
      client.screenshot(url: "https://example.com")

      assert_equal [["proxy.example", 443]], calls
      assert_equal "/api/v1/screenshot", fake.requests.first.uri.path
    end
  end

  def test_screenshot_requires_url_or_html
    client = ScreenshotAPI::Client.new(TEST_KEY)

    assert_raises(ArgumentError) { client.screenshot }
    assert_raises(ArgumentError) { client.screenshot(url: "") }
    assert_raises(ArgumentError) { client.screenshot(url: "   ") }
  end

  def test_builds_get_request_with_all_supported_query_params
    with_fake_http(success_response) do |fake, _calls|
      client = ScreenshotAPI::Client.new(TEST_KEY)
      client.screenshot(
        url: "https://example.com",
        width: 1280,
        height: 720,
        full_page: true,
        type: "webp",
        quality: 85,
        color_scheme: "dark",
        wait_until: "networkidle0",
        wait_for_selector: "#main",
        delay: 500,
        block_ads: false,
        remove_cookie_banners: true,
        css_inject: "body { background: white; }",
        js_inject: "window.ready = true;",
        stealth_mode: true,
        device_pixel_ratio: 2,
        timezone: "America/New_York",
        locale: "en-US",
        cache_ttl: 300,
        preload_fonts: true,
        remove_elements: [".ad", "#banner"],
        remove_popups: true,
        mockup_device: "browser",
        geo_latitude: 40.7128,
        geo_longitude: -74.006,
        geo_accuracy: 25
      )

      request = fake.requests.first
      params = query_hash(request)

      assert_instance_of Net::HTTP::Get, request
      assert_equal TEST_KEY, request["x-api-key"]
      assert_equal "https://example.com", params["url"]
      assert_equal "1280", params["width"]
      assert_equal "720", params["height"]
      assert_equal "true", params["fullPage"]
      assert_equal "webp", params["type"]
      assert_equal "85", params["quality"]
      assert_equal "dark", params["colorScheme"]
      assert_equal "networkidle0", params["waitUntil"]
      assert_equal "#main", params["waitForSelector"]
      assert_equal "500", params["delay"]
      assert_equal "false", params["blockAds"]
      assert_equal "true", params["removeCookieBanners"]
      assert_equal "body { background: white; }", params["cssInject"]
      assert_equal "window.ready = true;", params["jsInject"]
      assert_equal "true", params["stealthMode"]
      assert_equal "2", params["devicePixelRatio"]
      assert_equal "America/New_York", params["timezone"]
      assert_equal "en-US", params["locale"]
      assert_equal "300", params["cacheTtl"]
      assert_equal "true", params["preloadFonts"]
      assert_equal ".ad,#banner", params["removeElements"]
      assert_equal "true", params["removePopups"]
      assert_equal "browser", params["mockupDevice"]
      assert_equal "40.7128", params["geoLatitude"]
      assert_equal "-74.006", params["geoLongitude"]
      assert_equal "25", params["geoAccuracy"]
    end
  end

  def test_omits_optional_query_params_when_not_provided
    with_fake_http(success_response) do |fake, _calls|
      client = ScreenshotAPI::Client.new(TEST_KEY)
      client.screenshot(url: "https://example.com")

      params = query_hash(fake.requests.first)

      assert_equal ["url"], params.keys
    end
  end

  def test_html_capture_uses_post_json_body
    with_fake_http(success_response) do |fake, _calls|
      client = ScreenshotAPI::Client.new(TEST_KEY)
      client.screenshot(
        html: "<h1>Hello</h1>",
        width: 800,
        full_page: false,
        remove_elements: [".toast"]
      )

      request = fake.requests.first
      body = JSON.parse(request.body)

      assert_instance_of Net::HTTP::Post, request
      assert_equal "application/json", request["content-type"]
      assert_equal TEST_KEY, request["x-api-key"]
      assert_equal "<h1>Hello</h1>", body["html"]
      assert_equal 800, body["width"]
      assert_equal false, body["fullPage"]
      assert_equal [".toast"], body["removeElements"]
    end
  end

  def test_returns_result_metadata_and_content_type
    response = success_response(
      body: "binary-data",
      headers: {
        "content-type" => "image/webp",
        "x-credits-remaining" => "800",
        "x-screenshot-id" => "ss_xyz",
        "x-duration-ms" => "2345"
      }
    )

    with_fake_http(response) do
      client = ScreenshotAPI::Client.new(TEST_KEY)
      result = client.screenshot(url: "https://example.com")

      assert_equal "binary-data", result.image
      assert_equal "image/webp", result.content_type
      assert_equal 800, result.metadata.credits_remaining
      assert_equal "ss_xyz", result.metadata.screenshot_id
      assert_equal 2345, result.metadata.duration_ms
    end
  end

  def test_defaults_missing_metadata_headers
    response = success_response(headers: {
      "content-type" => nil,
      "x-credits-remaining" => nil,
      "x-screenshot-id" => nil,
      "x-duration-ms" => nil
    })

    with_fake_http(response) do
      client = ScreenshotAPI::Client.new(TEST_KEY)
      result = client.screenshot(url: "https://example.com")

      assert_equal "image/png", result.content_type
      assert_equal 0, result.metadata.credits_remaining
      assert_equal "", result.metadata.screenshot_id
      assert_equal 0, result.metadata.duration_ms
    end
  end

  def test_save_writes_image_and_returns_metadata
    Dir.mktmpdir do |dir|
      path = File.join(dir, "screenshot.png")

      with_fake_http(success_response(body: "image-bytes")) do
        client = ScreenshotAPI::Client.new(TEST_KEY)
        metadata = client.save(url: "https://example.com", path: path)

        assert_equal "image-bytes", File.binread(path)
        assert_equal "ss_test", metadata.screenshot_id
      end
    end
  end

  def test_handles_authentication_error
    response = error_response(401, JSON.generate("error" => "Invalid authentication"))

    with_fake_http(response) do
      error = assert_raises(ScreenshotAPI::AuthenticationError) do
        ScreenshotAPI::Client.new(TEST_KEY).screenshot(url: "https://example.com")
      end

      assert_equal 401, error.status
      assert_equal "authentication_error", error.code
      assert_equal "Invalid authentication", error.message
    end
  end

  def test_handles_insufficient_credits_error_with_balance
    response = error_response(402, JSON.generate("error" => "Not enough credits", "balance" => 5))

    with_fake_http(response) do
      error = assert_raises(ScreenshotAPI::InsufficientCreditsError) do
        ScreenshotAPI::Client.new(TEST_KEY).screenshot(url: "https://example.com")
      end

      assert_equal 402, error.status
      assert_equal "insufficient_credits", error.code
      assert_equal 5, error.balance
    end
  end

  def test_handles_insufficient_credits_error_with_credit_balance
    response = error_response(402, JSON.generate("message" => "Quota exhausted", "creditBalance" => 7))

    with_fake_http(response) do
      error = assert_raises(ScreenshotAPI::InsufficientCreditsError) do
        ScreenshotAPI::Client.new(TEST_KEY).screenshot(url: "https://example.com")
      end

      assert_equal "Quota exhausted", error.message
      assert_equal 7, error.balance
    end
  end

  def test_handles_invalid_api_key_error
    response = error_response(403, JSON.generate("error" => "API key is invalid"))

    with_fake_http(response) do
      error = assert_raises(ScreenshotAPI::InvalidAPIKeyError) do
        ScreenshotAPI::Client.new(TEST_KEY).screenshot(url: "https://example.com")
      end

      assert_equal 403, error.status
      assert_equal "invalid_api_key", error.code
    end
  end

  def test_handles_screenshot_failed_error
    response = error_response(500, JSON.generate("message" => "Render timed out"))

    with_fake_http(response) do
      error = assert_raises(ScreenshotAPI::ScreenshotFailedError) do
        ScreenshotAPI::Client.new(TEST_KEY).screenshot(url: "https://example.com")
      end

      assert_equal 500, error.status
      assert_equal "screenshot_failed", error.code
      assert_equal "Render timed out", error.message
    end
  end

  def test_handles_unknown_api_error
    response = error_response(429, JSON.generate("error" => "Rate limited"))

    with_fake_http(response) do
      error = assert_raises(ScreenshotAPI::APIError) do
        ScreenshotAPI::Client.new(TEST_KEY).screenshot(url: "https://example.com")
      end

      assert_equal 429, error.status
      assert_equal "unknown_error", error.code
      assert_equal "Rate limited", error.message
    end
  end

  def test_handles_non_json_error_response
    response = error_response(502, "Bad Gateway", message: "Bad Gateway")

    with_fake_http(response) do
      error = assert_raises(ScreenshotAPI::APIError) do
        ScreenshotAPI::Client.new(TEST_KEY).screenshot(url: "https://example.com")
      end

      assert_equal 502, error.status
      assert_equal "unknown_error", error.code
      assert_equal "HTTP 502", error.message
    end
  end

  def test_wraps_network_errors
    with_fake_http(nil, Timeout::Error.new("execution expired")) do
      error = assert_raises(ScreenshotAPI::NetworkError) do
        ScreenshotAPI::Client.new(TEST_KEY).screenshot(url: "https://example.com")
      end

      assert_nil error.status
      assert_equal "network_error", error.code
      assert_equal "execution expired", error.message
    end
  end
end
