# screenshotapi_to

Official Ruby SDK for [ScreenshotAPI](https://screenshotapi.to?utm_source=ruby_sdk&utm_medium=readme&utm_campaign=sdk&ref=ruby-sdk). Capture website screenshots, PDFs, and rendered page states with a small `net/http` client and no runtime dependencies.

## Installation

Add the gem to your Gemfile:

```ruby
gem "screenshotapi_to", require: "screenshotapi"
```

Then install:

```bash
bundle install
```

Or install directly:

```bash
gem install screenshotapi_to
```

## Authentication

Create a free ScreenshotAPI account and copy an API key from the dashboard:

- [Get an API key](https://screenshotapi.to/sign-up?utm_source=ruby_sdk&utm_medium=readme&utm_campaign=sdk&ref=ruby-sdk)
- [API documentation](https://screenshotapi.to/docs?utm_source=ruby_sdk&utm_medium=readme&utm_campaign=sdk&ref=ruby-sdk)

Keep the key on the server and load it from an environment variable:

```bash
export SCREENSHOTAPI_KEY="sk_live_your_key_here"
```

```ruby
require "screenshotapi"

client = ScreenshotAPI::Client.new(ENV.fetch("SCREENSHOTAPI_KEY"))
```

## First Screenshot

Capture a PNG and save it to disk:

```ruby
require "screenshotapi"

client = ScreenshotAPI::Client.new(ENV.fetch("SCREENSHOTAPI_KEY"))

metadata = client.save(
  url: "https://example.com",
  path: "screenshot.png"
)

puts "Screenshot ID: #{metadata.screenshot_id}"
puts "Credits remaining: #{metadata.credits_remaining}"
```

Use `screenshot` when you need the raw bytes:

```ruby
result = client.screenshot(url: "https://example.com", type: "webp")

File.binwrite("screenshot.webp", result.image)
puts result.content_type
puts result.metadata.duration_ms
```

## Advanced Options

All GET-compatible screenshot options can be passed as Ruby keyword arguments. The client converts snake_case keys to ScreenshotAPI query parameters.

```ruby
result = client.screenshot(
  url: "https://example.com/pricing",
  width: 1440,
  height: 1200,
  full_page: true,
  type: "webp",
  quality: 85,
  color_scheme: "dark",
  wait_until: "networkidle2",
  wait_for_selector: "main",
  delay: 500,
  block_ads: true,
  remove_cookie_banners: true,
  stealth_mode: true,
  device_pixel_ratio: 2,
  timezone: "America/New_York",
  locale: "en-US",
  cache_ttl: 300,
  preload_fonts: true,
  remove_elements: [".newsletter", "#cookie-banner"],
  remove_popups: true
)

File.binwrite("pricing.webp", result.image)
```

Render raw HTML with `html:`. This uses `POST /api/v1/screenshot` with a JSON body:

```ruby
result = client.screenshot(
  html: "<main><h1>Hello from Ruby</h1></main>",
  width: 800,
  height: 600,
  type: "png"
)
```

Generate a PDF:

```ruby
metadata = client.save(
  url: "https://example.com/report",
  type: "pdf",
  path: "report.pdf"
)
```

## API Reference

### `ScreenshotAPI::Client.new(api_key, base_url:, timeout:)`

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `api_key` | `String` | Yes | - | Your ScreenshotAPI key. |
| `base_url` | `String` | No | `https://screenshotapi.to` | API base URL. |
| `timeout` | `Integer` | No | `60` | Open and read timeout in seconds. |

### `client.screenshot(**options)`

Returns `ScreenshotAPI::Result`.

| Option | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `url` | `String` | Yes, unless `html` is provided | - | Absolute `http` or `https` URL to capture. |
| `html` | `String` | No | - | Raw HTML to render. Uses POST. |
| `width` | `Integer` | No | `1440` | Viewport width in pixels. |
| `height` | `Integer` | No | `900` | Viewport height in pixels. |
| `full_page` | `Boolean` | No | `false` | Capture the full scrollable page. |
| `type` | `String` | No | `"png"` | `"png"`, `"jpeg"`, `"webp"`, or `"pdf"`. |
| `quality` | `Integer` | No | `100` | JPEG/WebP quality from `1` to `100`. |
| `color_scheme` | `String` | No | - | `"light"` or `"dark"`. |
| `wait_until` | `String` | No | `"networkidle2"` | `"load"`, `"domcontentloaded"`, `"networkidle0"`, or `"networkidle2"`. |
| `wait_for_selector` | `String` | No | - | CSS selector to wait for before capture. |
| `delay` | `Integer` | No | `0` | Additional delay in milliseconds. |
| `block_ads` | `Boolean` | No | `false` | Remove ads before capture. |
| `remove_cookie_banners` | `Boolean` | No | `false` | Auto-remove common cookie consent dialogs. |
| `css_inject` | `String` | No | - | CSS to inject before capture. |
| `js_inject` | `String` | No | - | JavaScript to run before capture. |
| `stealth_mode` | `Boolean` | No | `false` | Enable anti-bot-detection mode. |
| `device_pixel_ratio` | `Integer` | No | `1` | Retina/HiDPI scale. Accepted values: `1`, `2`, `3`. |
| `timezone` | `String` | No | - | IANA timezone, such as `"America/New_York"`. |
| `locale` | `String` | No | - | BCP 47 locale, such as `"en-US"`. |
| `cache_ttl` | `Integer` | No | `0` | Response cache TTL in seconds. |
| `preload_fonts` | `Boolean` | No | `false` | Preload discovered Google Fonts before capture. |
| `remove_elements` | `Array<String>` | No | - | CSS selectors to remove before capture. |
| `remove_popups` | `Boolean` | No | `false` | Remove common popups and overlays. |
| `mockup_device` | `String` | No | - | `"browser"`, `"iphone"`, or `"macbook"`. |
| `geo_latitude`, `geo_longitude`, `geo_accuracy` | `Number` | No | - | Browser geolocation override for GET requests. |

### `client.save(path:, **options)`

Same options as `screenshot`, plus `path:`. Writes the response body to disk and returns `ScreenshotAPI::Metadata`.

## Error Handling

The SDK raises typed errors for API responses and network failures:

```ruby
require "screenshotapi"

client = ScreenshotAPI::Client.new(ENV.fetch("SCREENSHOTAPI_KEY"))

begin
  result = client.screenshot(url: "https://example.com")
  File.binwrite("screenshot.png", result.image)
rescue ScreenshotAPI::AuthenticationError
  warn "API key missing or malformed"
rescue ScreenshotAPI::InvalidAPIKeyError
  warn "API key revoked or invalid"
rescue ScreenshotAPI::InsufficientCreditsError => e
  warn "No credits remaining. Balance: #{e.balance}"
rescue ScreenshotAPI::ScreenshotFailedError => e
  warn "Screenshot capture failed: #{e.message}"
rescue ScreenshotAPI::NetworkError => e
  warn "Network error: #{e.message}"
rescue ScreenshotAPI::APIError => e
  warn "ScreenshotAPI error #{e.status}: #{e.message}"
end
```

## Examples

Runnable examples live in `examples/`:

- `examples/plain_ruby.rb` captures a screenshot from a plain Ruby script.
- `examples/rails_controller.rb` shows a Rails controller action that returns screenshot bytes with typed error responses.

Run the plain Ruby example with:

```bash
SCREENSHOTAPI_KEY="sk_live_your_key_here" ruby examples/plain_ruby.rb
```

## Pricing And Free Tier

New accounts include 200 free screenshots per month. Paid plans support higher monthly volume, credit packs, caching, webhooks, S3 upload, signed URLs, and priority support.

- [Start free](https://screenshotapi.to/sign-up?utm_source=ruby_sdk&utm_medium=readme&utm_campaign=sdk&ref=ruby-sdk)
- [View pricing](https://screenshotapi.to/pricing?utm_source=ruby_sdk&utm_medium=readme&utm_campaign=sdk&ref=ruby-sdk)

## Documentation And Support

- [Ruby SDK documentation](https://screenshotapi.to/docs/sdks/ruby?utm_source=ruby_sdk&utm_medium=readme&utm_campaign=sdk&ref=ruby-sdk)
- [Screenshot API reference](https://screenshotapi.to/docs/api/screenshot?utm_source=ruby_sdk&utm_medium=readme&utm_campaign=sdk&ref=ruby-sdk)
- [Email support](mailto:support@screenshotapi.to)

## Requirements

- Ruby 3.0+
- No runtime gem dependencies. The client uses `net/http`, `json`, and `uri` from the Ruby standard library.

## License

MIT
