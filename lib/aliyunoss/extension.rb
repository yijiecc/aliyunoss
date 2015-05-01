class Hash
  # Convert hash to http query string
  def to_query_string
    array = Array.new
    self.each_pair {|k,v| array << (if v then k+"="+v else k end)}
    array.join('&')
  end
end

class String
  # Convert http query string to hash
  def query_string_to_hash
    hash = Hash.new
    self.split('&').each do |q|
      if q["="]
        k,v = q.split('=')
        hash[k] = v
      else
        hash[q] = nil
      end
    end
    hash
  end

  # Convert CamelCase to ruby_case
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end

end
