require_relative "test_helper"

class ErrorsTest < Minitest::Test
  def test_api_error_stores_status_and_code
    error = ScreenshotAPI::APIError.new("something broke", status: 418, code: "teapot")

    assert_equal "something broke", error.message
    assert_equal 418, error.status
    assert_equal "teapot", error.code
    assert_kind_of StandardError, error
  end

  def test_authentication_error
    error = ScreenshotAPI::AuthenticationError.new("bad credentials")

    assert_equal 401, error.status
    assert_equal "authentication_error", error.code
    assert_equal "bad credentials", error.message
    assert_kind_of ScreenshotAPI::APIError, error
  end

  def test_insufficient_credits_error
    error = ScreenshotAPI::InsufficientCreditsError.new("no credits", balance: 42)

    assert_equal 402, error.status
    assert_equal "insufficient_credits", error.code
    assert_equal "no credits", error.message
    assert_equal 42, error.balance
    assert_kind_of ScreenshotAPI::APIError, error
  end

  def test_invalid_api_key_error
    error = ScreenshotAPI::InvalidAPIKeyError.new("bad key")

    assert_equal 403, error.status
    assert_equal "invalid_api_key", error.code
    assert_equal "bad key", error.message
    assert_kind_of ScreenshotAPI::APIError, error
  end

  def test_screenshot_failed_error
    error = ScreenshotAPI::ScreenshotFailedError.new("render failed")

    assert_equal 500, error.status
    assert_equal "screenshot_failed", error.code
    assert_equal "render failed", error.message
    assert_kind_of ScreenshotAPI::APIError, error
  end

  def test_network_error
    error = ScreenshotAPI::NetworkError.new("connection failed")

    assert_nil error.status
    assert_equal "network_error", error.code
    assert_equal "connection failed", error.message
    assert_kind_of ScreenshotAPI::APIError, error
  end
end
