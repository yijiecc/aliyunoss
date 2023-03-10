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
          uri = URI("http://#{domain}/")
        else
          if @bucket
            uri = URI("http://#{bucket.name}.#{bucket.location}.#{host}")
          else
            uri = URI("http://oss.#{host}")
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
          Net::HTTP.start(uri.host, uri.port) do |http|
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
      # 1) ???????????????x-oss-??????????????? HTTP ????????????????????????????????????????????? ???X-OSS-Meta-Name: TaoBao???
      #    ????????? ???x-oss-meta-name: TaoBao??? ???
      # 2) ??????????????????????????? HTTP ?????????????????????????????????????????????
      # 3) ?????????????????????????????????,??????????????? RFC 2616, 4.2 ???????????????(?????????????????????????????????)???
      #    ?????????????????????x-oss-meta-name???????????????,????????????????????????TaoBao?????????Alipay???,????????????
      #    ???: ???x-oss-meta-name:TaoBao,Alipay??? ???
      # 4) ?????????????????????????????????????????????????????????????????????
      #    ??? ???x-oss-meta-name: TaoBao,Alipay??? ?????????: ???x-oss-meta-name:TaoBao,Alipay??? ???
      # 5) ??????????????????????????? ???\n??? ?????????????????????????????? CanonicalizedOSSHeader ???
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
      # 1) ??? CanonicalizedResource ??????????????????( ?????? );
      # 2) ?????????????????? OSS ??????:??? /BucketName/ObjectName ???(??? ObjectName ?????????)
      # 3) ???????????????????????????????????? (sub-resource) ,??????????????????????????????????????????,?????????????????????
      #    ??? ???&??? ?????????????????????????????????????????? CanonicalizedResource ????????????????????????????????????????
      #    ?????????????????? CanonicalizedResource ?????????: /BucketName/ObjectName?acl &uploadId=UploadId
      # 4) ???????????????????????????????????? (query string) ????????????????????? (override) ??????????????? header,????????????
      #    ????????????????????????????????????????????????,??????????????????,??? ???&??? ????????????,??????????????????????????????
      #    CanonicalizedResource ??????????????? CanonicalizedResource ??????:
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
