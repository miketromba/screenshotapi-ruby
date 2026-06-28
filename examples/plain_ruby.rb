require "screenshotapi"

api_key = ENV["SCREENSHOTAPI_KEY"]
abort "Set SCREENSHOTAPI_KEY before running this example." if api_key.nil? || api_key.strip.empty?

client = ScreenshotAPI::Client.new(api_key)

begin
  metadata = client.save(
    url: "https://example.com",
    path: "example.png",
    width: 1440,
    height: 900,
    full_page: true,
    type: "png",
    block_ads: true,
    remove_cookie_banners: true
  )

  puts "Saved example.png"
  puts "Screenshot ID: #{metadata.screenshot_id}"
  puts "Credits remaining: #{metadata.credits_remaining}"
rescue ScreenshotAPI::InsufficientCreditsError => e
  warn "ScreenshotAPI credits exhausted. Balance: #{e.balance}"
  exit 1
rescue ScreenshotAPI::APIError => e
  warn "ScreenshotAPI request failed (#{e.code}, HTTP #{e.status || "n/a"}): #{e.message}"
  exit 1
end
