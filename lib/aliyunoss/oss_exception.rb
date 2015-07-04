class OssException < RuntimeError
  def initialize(http_response)
    @response = http_response
  end

  def inspect
    "Status: #{@response.class.to_s}\nBody: #{@response.body}"
  end

  def to_s
    inspect
  end

  def message
    inspect
  end
end
