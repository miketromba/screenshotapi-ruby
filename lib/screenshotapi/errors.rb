module ScreenshotAPI
  class APIError < StandardError
    attr_reader :status, :code

    def initialize(message, status:, code:)
      super(message)
      @status = status
      @code = code
    end
  end

  class AuthenticationError < APIError
    def initialize(message)
      super(message, status: 401, code: "authentication_error")
    end
  end

  class InsufficientCreditsError < APIError
    attr_reader :balance

    def initialize(message, balance: 0)
      super(message, status: 402, code: "insufficient_credits")
      @balance = balance
    end
  end

  class InvalidAPIKeyError < APIError
    def initialize(message)
      super(message, status: 403, code: "invalid_api_key")
    end
  end

  class ScreenshotFailedError < APIError
    def initialize(message)
      super(message, status: 500, code: "screenshot_failed")
    end
  end

  class NetworkError < APIError
    def initialize(message)
      super(message, status: nil, code: "network_error")
    end
  end
end
