# coding: utf-8
require 'base64'
require 'openssl'

module Aliyun
  module Oss

    class OssRequest
      
      include ConfigHelper
      attr_accessor :bucket, :path, :body, :queris, :domain

      #
      # Create a new oss request, parameters will be sent to methods of Net::HTTP later.
      # 
      def initialize(bucket, path, domain = nil, queries = {}, headers = {})
        @bucket = bucket
        @path = path
        @queries = queries
        @domain = domain
        @headers = {"Content-Type" => "", "Content-MD5" => "", "Date" => Time.now.utc.strftime('%a, %d %b %Y %H:%M:%S GMT')}.merge(headers)
      end

      #
      # Get complete url for this request
      # 
      def get_uri
        if @domain
          uri = URI("https://#{@domain}/")
        else
          if @bucket
            uri = URI("https://#{@bucket.name}.#{@bucket.location}.#{host}")
          else
            uri = URI("https://oss.#{host}")
          end
        end
        uri.path = @path
        uri.query = @queries.to_query_string if @queries.count > 0
        uri
      end

      def self.add_operation(verb)
        define_method(verb) do
          uri = get_uri

          request = Net::HTTP.send(:const_get, verb.to_s.capitalize).new(uri)
          
          @headers.each_pair {|k,v| request[k] = v}
          
          if @body
            request.body = @body
            digest = OpenSSL::Digest::MD5.digest(@body)
            request['Content-MD5'] = Base64.encode64(digest).strip
            request['Content-Length'] = @body.bytesize
          end

          request['Authorization'] = 'OSS ' +  access_key_id + ':' +
                                     signature(request)
        
          logger.info(verb.to_s.upcase + ' ' + uri.to_s + ' ' + request.to_hash.to_s)
          
          response = nil
          Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
            response = http.request(request)
            logger.info(response.code.to_s + ' ' + response.message)
          end
          response          
        end
      end

      add_operation :get
      add_operation :put
      add_operation :delete
      add_operation :head
      add_operation :post

      #
      # Get sharing url for this request, pass _expires_in_ as parameter.
      # 
      def url_for_sharing(expires_in)
        uri = get_uri
        request = Net::HTTP::Get.new(uri)
        @headers.each_pair {|k,v| request[k] = v}
        expires_at = (Time.now + expires_in).utc.to_i
        request["Date"] = expires_at
        uri.query = URI.encode_www_form({"OSSAccessKeyId" => access_key_id,
                                         "Expires" => expires_at,
                                         "Signature" => signature(request)})
        uri.to_s
      end

      def headers_for_write(filename: nil, content_type:, content_length:, 
                            checksum:, custom_metadata: {})
        @headers = {
          "Content-Type" => content_type, 
          "Content-MD5" => checksum, 
          "Date" => Time.now.utc.strftime('%a, %d %b %Y %H:%M:%S GMT'),
          "Content-Length" => content_length
        }

        @headers["x-oss-date"] = @headers["Date"]

        if filename != nil
          @headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
        end

        request = Net::HTTP.send(:const_get, 'Put').new(get_uri)
        @headers.each_pair {|k,v| request[k] = v}
        @headers['Authorization'] = 'OSS ' +  access_key_id + ':' + signature(request)
        @headers
      end

      #
      # Get http header value by attribute 
      # 
      def [](key)
        @headers[key]
      end

      #
      # Set http header value by attribute
      # 
      def []=(key, value)
        @headers[key] = value
      end

      private
      def signature(req)
        verb = req.class.to_s.gsub(/Net::HTTP::/, '').upcase
        data = verb + "\n" + req["Content-MD5"] + "\n" +
               req["Content-Type"] + "\n" + req["Date"] + "\n" +
               canonicalized_oss_headers(req) + 
               canonicalized_resource()
        
        digest = OpenSSL::Digest.new('sha1')
        hmac = OpenSSL::HMAC.digest(digest, access_key_secret, data)
        Base64.encode64(hmac).strip
      end

      # oss api 20140828.pdf - 4.2
      # 1) 将所有以“x-oss-”为前缀的 HTTP 请求头的名字转换成小写字母。如 ’X-OSS-Meta-Name: TaoBao’
      #    转换成 ’x-oss-meta-name: TaoBao’ 。
      # 2) 将上一步得到的所有 HTTP 请求头按照字典序进行升序排列。
      # 3) 如果有相同名字的请求头,则根据标准 RFC 2616, 4.2 章进行合并(两个值之间只用逗号分隔)。
      #    如有两个名为’x-oss-meta-name’的请求头,对应的值分别为’TaoBao’和’Alipay’,则合并后
      #    为: ’x-oss-meta-name:TaoBao,Alipay’ 。
      # 4) 删除请求头和内容之间分隔符两端出现的任何空格。
      #    如 ’x-oss-meta-name: TaoBao,Alipay’ 转换成: ’x-oss-meta-name:TaoBao,Alipay’ 。
      # 5) 将所有的头和内容用 ’\n’ 分隔符分隔拼成最后的 CanonicalizedOSSHeader 。
      def canonicalized_oss_headers(req)
        hash = Hash.new
        req.each_header do |header|          
          header = header.to_s.downcase
          next unless header.start_with?('x-oss-')
          if hash.has_key?(header)
            hash[header] = hash[header] + "," + req[header].strip
          else
            hash[header] = req[header].strip
          end
        end

        return "" if hash.count == 0
        hash.keys.sort.map{|k| "#{k}:#{hash[k]}"}.join("\n") << "\n"
      end

      # oss api 20140828.pdf - 4.2
      # 1) 将 CanonicalizedResource 置成空字符串( “” );
      # 2) 放入要访问的 OSS 资源:“ /BucketName/ObjectName ”(无 ObjectName 则不填)
      # 3) 如果请求的资源包括子资源 (sub-resource) ,那么将所有的子资源按照字典序,从小到大排列并
      #    以 ’&’ 为分隔符生成子资源字符串。在 CanonicalizedResource 字符串尾添加“?”和子资源字
      #    符串。此时的 CanonicalizedResource 例子如: /BucketName/ObjectName?acl &uploadId=UploadId
      # 4) 如果用户请求在查询字符串 (query string) 中指定了要重写 (override) 返回请求的 header,那么将这
      #    些查询字符串及其请求值按照字典序,从小到大排列,以 ’&’ 为分隔符,按参数的字典序添加到
      #    CanonicalizedResource 中。此时的 CanonicalizedResource 例子:
      #    /BucketName/ObjectName?acl&response-content-type=ContentType & uploadId =UploadId
      def canonicalized_resource()
        return @path unless @bucket
        return "/#{@bucket.name}#{@path}" if @queries.count == 0

        array =  @queries.keys.sort.map do |k|
          if @queries[k] then "#{k}=#{@queries[k]}" else "#{k}" end
        end
          

        "/#{@bucket.name}#{@path}?#{array.sort.join('&')}"
      end

    end
    
  end
end
