module Aliyun
  module Oss

    module API
      extend self

      # Reference
      # http://docs-aliyun-com-cn-b.oss-cn-hangzhou.aliyuncs.com/oss/pdf/oss_api-reference.pdf

      # List all buckets
      def list_bucket(params = {})
        Aliyun::Oss::OssRequest.new(nil, '/', nil, {}, {}).get
      end
      alias :get_service :list_bucket

      # Create a new bucket
      def put_bucket(name, location = 'oss-cn-hangzhou')
        bucket = Bucket.new(name: name, location: location)
        request = Aliyun::Oss::OssRequest.new(bucket, '/')
        request.body = <<HERE
<?xml version="1.0" encoding="UTF-8"?>
<CreateBucketConfiguration>
<LocationConstraint>#{location}</LocationConstraint>
</CreateBucketConfiguration>
HERE
        request.put
      end
      alias :create_bucket :put_bucket

      # Delete a bucket
      def delete_bucket(bucket)
        Aliyun::Oss::OssRequest.new(bucket, '/').delete
      end
        
      # Delete bucket logging
      def delete_logging(bucket)
        Aliyun::Oss::OssRequest.new(bucket, '/', nil, 'logging'=>nil).delete
      end

      # Delete bucket website
      def delete_website(bucket)
        Aliyun::Oss::OssRequest.new(bucket, '/', nil, 'website'=>nil).delete
      end
      alias :disable_website :delete_website

      # List objects in bucket
      def list_object(bucket, queries = {})
        Aliyun::Oss::OssRequest.new(bucket, '/', nil, queries).get
      end

      # Get bucket acl
      def get_bucket_acl(bucket)
        Aliyun::Oss::OssRequest.new(bucket, '/', nil, 'acl'=>nil).get
      end

      # Get bucket location
      def get_bucket_location(bucket)
        Aliyun::Oss::OssRequest.new(bucket, '/', nil, 'location'=>nil).get
      end

      # Query bucket logging status
      def get_bucket_logging(bucket)
        Aliyun::Oss::OssRequest.new(bucket, '/', nil, 'logging'=>nil).get
      end

      # Query bucket website status
      def get_bucket_website(bucket)
        Aliyun::Oss::OssRequest.new(bucket, '/', nil, 'website'=>nil).get
      end

      # Set bucket acl permission
      def put_bucket_acl(bucket, permission)
        Aliyun::Oss::OssRequest.new(bucket, '/', nil, {}, 'x-oss-acl'=> permission).put
      end
      alias :set_bucket_acl :put_bucket_acl

      # Enable or disable bucket logging
      def enable_bucket_logging(bucket, bucket_name_for_logging, log_prefix)
        request = Aliyun::Oss::OssRequest.new(bucket, '/', nil, 'logging'=>nil)
        request.body = <<HERE
<?xml version="1.0" encoding="UTF-8"?>
<BucketLoggingStatus>
  <LoggingEnabled>
    <TargetBucket>#{bucket_name_for_logging}</TargetBucket>
    <TargetPrefix>#{log_prefix}</TargetPrefix>
  </LoggingEnabled>
</BucketLoggingStatus>
HERE
        request['Content-Type'] = 'application/xml'
        request.put
      end

      def disable_bucket_logging(bucket)
        request = Aliyun::Oss::OssRequest.new(bucket, '/', nil, 'logging'=>nil)
        request.body = <<HERE
<?xml version="1.0" encoding="UTF-8"?>
<BucketLoggingStatus>
</BucketLoggingStatus>
HERE
        request['Content-Type'] = 'application/xml'
        request.put        
      end

      # Set bucket website access
      def put_bucket_website(bucket, index_page, error_page)
        request = Aliyun::Oss::OssRequest.new(bucket, '/', nil, 'website'=>nil)
        request.body = <<HERE
<?xml version="1.0" encoding="UTF-8"?>
<WebsiteConfiguration>
  <IndexDocument>
    <Suffix>#{index_page}</Suffix>
  </IndexDocument>
  <ErrorDocument>
    <Key>#{error_page}</Key>
  </ErrorDocument>
</WebsiteConfiguration>
HERE
        request['Content-Type'] = 'application/xml'
        request.put
      end
      alias :set_bucket_website :put_bucket_website
      
      # Copy Object
      def copy_object(source_bucket, source_path, target_bucket, target_path, headers = {})
        headers = headers.merge({'x-oss-copy-source'=> "/" + source_bucket.name + source_path})
        Aliyun::Oss::OssRequest.new(target_bucket, target_path, nil, {}, headers).put
      end

      # Delete Object
      def delete_object(bucket, path)
        Aliyun::Oss::OssRequest.new(bucket, path).delete
      end

      # Delete Multiple Object
      def delete_multiple_objects(bucket, objects, quiet_mode = false)
        xml = '<?xml version="1.0" encoding="UTF-8"?>'
        xml << '<Delete>'
        xml << "<Quiet>#{quiet_mode}</Quiet>"
        objects.each {|o| xml << "<Object><Key>#{o}</Key></Object>"}
        xml << '</Delete>'
        request = Aliyun::Oss::OssRequest.new(bucket, '/', nil, 'delete'=>nil)
        request.body = xml
        request.post
      end

      # Get Object
      def get_object(bucket, path, headers = {})
        Aliyun::Oss::OssRequest.new(bucket, path, nil, {}, headers).get
      end

      # Head Object
      def head_object(bucket, path, headers = {})
        Aliyun::Oss::OssRequest.new(bucket, path, nil, {}, headers).head
      end

      # Put Object
      def put_object(bucket, path, data, headers = {})
        request = Aliyun::Oss::OssRequest.new(bucket, path, nil, {}, headers)
        request.body = data
        request.put
      end

      # get share url for specified object
      def generate_share_url(bucket, path, expires_in = 3600)
        Aliyun::Oss::OssRequest.new(bucket, path).url_for_sharing(expires_in)
      end

      # Post Object
      # Not implemented

      # Post Policy
      # Not implemented

      # Post signature
      # Not implemented

      # Multipart Initiate
      def multipart_upload_initiate(bucket, path)
        Aliyun::Oss::OssRequest.new(bucket, path, nil, 'uploads'=>nil).post
      end

      def multipart_upload_part(bucket, path, upload_id, data, part_number)
        request = Aliyun::Oss::OssRequest.new(bucket, path, nil, 'partNumber'=> part_number.to_s, 'uploadId'=> upload_id)
        request.body = data
        request.put
      end

      def multipart_upload_from_copy(upload_id, source_bucket, source_path, target_bucket, target_path, part_number, part_size, range = nil)
        request = Aliyun::Oss::OssRequest.new(target_bucket, target_path, nil, 'partNumber'=> part_number.to_s, 'uploadId'=> upload_id)
        request['Content-Length'] = part_size
        request['x-oss-copy-source'] = "/" + source_bucket.name + source_path
        request['x-oss-copy-source-range'] = range if range
        request.put
      end

      def multipart_upload_complete(bucket, path, upload_id, part_list)
        request = Aliyun::Oss::OssRequest.new(bucket, path, nil, 'uploadId'=> upload_id)
        xml = '<?xml version="1.0" encoding="UTF-8"?>'   
        xml << '<CompleteMultipartUpload>'
        part_list.each_pair {|k,v| xml << "<Part><PartNumber>#{k}</PartNumber><ETag>#{v}</ETag></Part>"}
        xml << '</CompleteMultipartUpload>'
        request.body = xml
        request.post
      end

      def multipart_upload_abort(bucket, path, upload_id)
        Aliyun::Oss::OssRequest.new(bucket, path, nil, 'uploadId'=> upload_id).delete
      end

      def multipart_upload_finished_parts(bucket, path, upload_id)
        Aliyun::Oss::OssRequest.new(bucket, path, nil, 'uploadId'=> upload_id).get
      end

      def multipart_upload_unfinished_task(bucket)
        Aliyun::Oss::OssRequest.new(bucket, '/', nil, 'uploads'=>nil).get
      end
      
    end
      
  end
end




