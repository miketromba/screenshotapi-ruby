require "screenshotapi"

class ScreenshotsController < ApplicationController
  def show
    result = screenshot_client.screenshot(
      url: params.require(:url),
      width: params.fetch(:width, 1440).to_i,
      height: params.fetch(:height, 900).to_i,
      type: params.fetch(:type, "png"),
      full_page: ActiveModel::Type::Boolean.new.cast(params[:full_page]),
      block_ads: true,
      remove_cookie_banners: true
    )

    expires_in 1.hour, public: true
    send_data result.image, type: result.content_type, disposition: "inline"
  rescue ActionController::ParameterMissing
    render json: { error: "url is required" }, status: :bad_request
  rescue ScreenshotAPI::InsufficientCreditsError => e
    render json: { error: "insufficient credits", balance: e.balance }, status: :payment_required
  rescue ScreenshotAPI::AuthenticationError, ScreenshotAPI::InvalidAPIKeyError
    render json: { error: "ScreenshotAPI authentication failed" }, status: :unauthorized
  rescue ScreenshotAPI::APIError => e
    Rails.logger.warn("ScreenshotAPI failed: #{e.code} #{e.message}")
    render json: { error: "screenshot capture failed" }, status: :bad_gateway
  end

  private

  def screenshot_client
    @screenshot_client ||= ScreenshotAPI::Client.new(
      Rails.application.credentials.dig(:screenshotapi, :api_key)
    )
  end
end
