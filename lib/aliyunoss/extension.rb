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

# add methods to HTTPResponse for parsing results
module Net

  class HTTPResponse

    def raise_unless(status)
      raise OssException.new(self) unless status === self
      self
    end

    def to_buckets
      raise message unless Net::HTTPOK === self
      nodes = Nokogiri::XML(self.body).xpath('//Bucket') rescue []
      nodes.map do |node|
        bucket = Aliyun::Oss::Bucket.new
        node.elements.each {|e| bucket.send("#{e.name.underscore}=".to_sym, e.content) rescue nil }
        bucket
      end
    end

    def to_objects
      raise message unless Net::HTTPOK === self
      nodes = Nokogiri::XML(self.body).xpath('//Contents') rescue []
      nodes.map do |node|
        hash = Hash.new
        node.elements.each {|e| hash[e.name.underscore] = e.content unless e.name == 'Owner' }
        hash
      end      
    end

    def to_logging_status
      raise message unless Net::HTTPOK === self
      node = Nokogiri::XML(self.body).xpath('//LoggingEnabled') rescue []
      hash = Hash.new
      node[0].elements.each {|e| hash[e.name.underscore] = e.content }
      hash                                                     
    end

    def to_website_status
      raise message unless Net::HTTPOK === self
      xml = Nokogiri::XML(self.body)
      {'index_page' => xml.xpath('//Suffix')[0].content, 'error_page' => xml.xpath('//Key')[0].content } rescue {}
    end

    def to_acl_status
      raise message unless Net::HTTPOK === self
      Nokogiri::XML(self.body).xpath('//Grant')[0].content
    end

    def to_multipart_id
      raise message unless Net::HTTPOK === self
      Nokogiri::XML(body).xpath('//UploadId').first.content      
    end

    def to_mutlipart_task
      raise message unless Net::HTTPOK === self
      tasks = Array.new
      nodes = Nokogiri::XML(response.body).xpath('//Upload')
      nodes.each do |node|
        path = '/' + node.xpath('Key').first.content
        id = node.xpath('UploadId').first.content
        tasks << {'path'=> path, 'upload_id' => id}
      end
      tasks
    end
  end
  
end
