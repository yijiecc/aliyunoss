module Aliyun
  module Oss

    class Bucket
      attr_accessor :location, :name, :creation_date, :domain, :extranet_endpoint, :intranet_endpoint

      def initialize(params = {})
        params.each_pair {|k,v| send("#{k.to_s}=", v) }
        if String === @creation_date
          @creation_date =~ /(\d+) ([a-zA-Z]+) (\d+) (\d\d):(\d\d):(\d\d)/
          @creation_date = Time.gm($3, $2, $1, $4, $5, $6)
        end
      end

      # 
      # Class method - List all buckets in my account
      # 
      def self.all
        Aliyun::Oss::API.list_bucket.raise_unless(Net::HTTPOK).to_buckets
      end

      #
      # Class method - Create a new bucket
      # 
      def self.create(name, location = 'oss-cn-hangzhou')
        Aliyun::Oss::API.put_bucket(name, location).raise_unless(Net::HTTPOK)
        Bucket.new(:name => name,  :location=> location, :creation_date => Time.now)
      end

      # 
      # List all files in an bucket
      # 
      def list_files(options = {})
        Aliyun::Oss::API.list_object(self, options).raise_unless(Net::HTTPOK).to_objects
      end

      #
      # Upload data to bucket
      # 
      def upload(data, path, options = {})
        Aliyun::Oss::API.put_object(self, path, data, options).raise_unless(Net::HTTPOK)
      end

      #
      # Download file from remote server
      # 
      def download(path, options = {})
        Aliyun::Oss::API.get_object(self, path, options)
          .raise_unless(Net::HTTPOK)
          .body
      end

      # 
      # Get file info 
      # 
      def get_file_info(path)
        hash = Hash.new
        Aliyun::Oss::API.head_object(self, path).raise_unless(Net::HTTPOK).each_header do |k,v|
          hash[k] = v
        end
        hash
      end

      # 
      # Test if a file exist
      # return true/false
      # 
      def exist?(path)
        begin
          Aliyun::Oss::API.head_object(self, path).raise_unless(Net::HTTPOK)
          true
        rescue OssException => ex
          if (ex.message.include? 'Net::HTTPNotFound') 
            false
          else
            raise ex
          end
        end
      end

      #
      # Generate a url that can be shared to others
      # 
      def share(path, expires_in = 3600)
        Aliyun::Oss::API.generate_share_url(self, path, expires_in)
      end

      # 
      # Generate public url for path
      # 
      def public_url(path)
        "https://#{name}.#{location}.aliyuncs.com#{path}"
      end

      #
      # Delete remote file
      # 
      def delete(path)
        Aliyun::Oss::API.delete_object(self, path).raise_unless(Net::HTTPNoContent)
      end

      # 
      # Multipart upload and copy
      # 
      def multipart_pending
        Aliyun::Oss::API.multipart_upload_unfinished_task(self)
          .raise_unless(Net::HTTPOK)
          .to_mutlipart_task
      end

      def multipart_abort(path, upload_id)
        Aliyun::Oss::API.multipart_upload_abort(self, path, upload_id)
          .raise_unless(Net::HTTPNoContent)
      end

      def multipart_upload(data)
        raise 'You must call multipart_upload_initiate before upload data.' unless @multipart_path
        response = Aliyun::Oss::API.multipart_upload_part(self, @multipart_path,
                                               @multipart_id,
                                               data, @multipart_sequence)
        response.raise_unless(Net::HTTPOK)
        @multipart_list[@multipart_sequence] = response['ETag']
        @multipart_sequence = @multipart_sequence + 1
      end

      def multipart_copy_from(source_bucket, source_path, size, range = nil)
        response = Aliyun::Oss::API.multipart_upload_from_copy(@multipart_id,
                                                               source_bucket, source_path,
                                                               self, @multipart_path,
                                                               @multipart_sequence,
                                                               size, range)
        response.raise_unless(Net::HTTPOK)
        @multipart_list[@multipart_sequence] = response['ETag']
        @multipart_sequence = @multipart_sequence + 1        
      end

      def multipart_upload_initiate(path)
        @multipart_path = path
        @multipart_id = Aliyun::Oss::API.multipart_upload_initiate(self, path)
                        .raise_unless(Net::HTTPOK)
                        .to_multipart_id
        @multipart_list = {}
        @multipart_sequence = 1
      end

      def multipart_upload_complete
        Aliyun::Oss::API.multipart_upload_complete(self, @multipart_path,
                                                   @multipart_id,
                                                   @multipart_list)
          .raise_unless(Net::HTTPOK)
        @multipart_path = nil
      end

      # 
      # delete this bucket
      # 
      def delete!
        Aliyun::Oss::API.delete_bucket(self).raise_unless(Net::HTTPNoContent)
      end

      def disable_logging
        Aliyun::Oss::API.delete_logging(self).raise_unless(Net::HTTPNoContent)
      end

      def enable_logging(target_bucket_name, log_prefix)
        Aliyun::Oss::API.enable_bucket_logging(self, target_bucket_name, log_prefix).raise_unless(Net::HTTPOK)
      end

      def logging_status
        Aliyun::Oss::API.get_bucket_logging(self).raise_unless(Net::HTTPOK).to_logging_status
      end

      def disable_website_access
        Aliyun::Oss::API.delete_website(self).raise_unless(Net::HTTPNoContent)
      end

      def enable_website_access(index_page, error_page)
        Aliyun::Oss::API.put_bucket_website(self, index_page, error_page).raise_unless(Net::HTTPOK)
      end

      def website_access_status
        Aliyun::Oss::API.get_bucket_website(self).raise_unless(Net::HTTPOK).to_website_status
      end

      def set_acl(permission)
        Aliyun::Oss::API.put_bucket_acl(self, permission).raise_unless(Net::HTTPOK)
      end

      def get_acl
        Aliyun::Oss::API.get_bucket_acl(self).raise_unless(Net::HTTPOK).to_acl_status
      end
    end
    
  end
end
