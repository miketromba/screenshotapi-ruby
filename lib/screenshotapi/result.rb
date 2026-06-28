module ScreenshotAPI
  class Metadata
    attr_reader :credits_remaining, :screenshot_id, :duration_ms

    def initialize(credits_remaining:, screenshot_id:, duration_ms:)
      @credits_remaining = credits_remaining
      @screenshot_id = screenshot_id
      @duration_ms = duration_ms
    end
  end

  class Result
    attr_reader :image, :content_type, :metadata

    def initialize(image:, content_type:, metadata:)
      @image = image
      @content_type = content_type
      @metadata = metadata
    end
  end
end
