module Rechanize
  class RequestError < StandardError; end
  class InvalidPathError < StandardError; end
  class UnsupportedRequest < StandardError; end
  class AuthenticationError < StandardError; end
  
  class UnsupportedContentType < StandardError; end
  class MultipartError < UnsupportedContentType; end
end
