module Aliyun
  module Oss

    class Bucket
      attr_accessor :location, :name, :creation_date

      def initialize(params = {})
        params.each_pair {|k,v| send("#{k.to_s}=", v) }
        if String === @creation_date
          @creation_date =~ /(\d+) ([a-zA-Z]+) (\d+) (\d\d):(\d\d):(\d\d)/
          @creation_date = Time.gm($3, $2, $1, $4, $5, $6)
        end
      end

      # Class methods
      def self.all
        Aliyun::Oss::API.list_bucket.to_buckets
      end

      def self.create(name, location = 'oss-cn-hangzhou')
        if Aliyun::Oss::API.put_bucket(name, location).class == Net::HTTPOK
          Bucket.new(:name => name,  :location=> location, :creation_date => Time.now)
        else
          nil
        end
      end

      # Instance Methods -- object download and upload
      def list_files(options = {})
        Aliyun::Oss::API.list_object(self, options).to_objects
      end

      def upload(data, path, options = {})
        Aliyun::Oss::API.put_object(self, path, data, options).raise_if_not(Net::HTTPOK)
      end

      def download(path, options = {})
        response = Aliyun::Oss::API.get_object(self, path, options)
        response.raise_if_not(Net::HTTPOK)
        response.body
      end

      def delete(path)
        Aliyun::Oss::API.delete_object(self, path).raise_if_not(Net::HTTPNoContent)
      end

      # Multipart upload and copy
      def multipart_pending
        Aliyun::Oss::API.multipart_upload_unfinished_task(self).to_mutlipart_task
      end

      def multipart_abort(path, upload_id)
        Aliyun::Oss::API.multipart_upload_abort(self, path, upload_id).raise_if_not(Net::HTTPNoContent)
      end

      def multipart_upload(data)
        raise 'You must call multipart_upload_initiate before upload data.' unless @multipart_path
        response = Aliyun::Oss::API.multipart_upload_part(self, @multipart_path,
                                               @multipart_id,
                                               data, @multipart_sequence)
        response.raise_if_not(Net::HTTPOK)
        @multipart_list[@multipart_sequence] = response['ETag']
        @multipart_sequence = @multipart_sequence + 1
      end

      def multipart_copy_from(source_bucket, source_path, size, range = nil)
        response = Aliyun::Oss::API.multipart_upload_from_copy(@multipart_id,
                                                               source_bucket, source_path,
                                                               self, @multipart_path,
                                                               @multipart_sequence,
                                                               size, range)
        response.raise_if_not(Net::HTTPOK)
        @multipart_list[@multipart_sequence] = response['ETag']
        @multipart_sequence = @multipart_sequence + 1        
      end

      def multipart_upload_initiate(path)
        @multipart_path = path
        @multipart_id = Aliyun::Oss::API.multipart_upload_initiate(self, path).to_multipart_id
        @multipart_list = {}
        @multipart_sequence = 1
      end

      def multipart_upload_complete
        Aliyun::Oss::API.multipart_upload_complete(self, @multipart_path,
                                                   @multipart_id,
                                                   @multipart_list)
          .raise_if_not(Net::HTTPOK)
        @multipart_path = nil
      end

      # Instance Methods -- miscellaneous
      def delete!
        Aliyun::Oss::API.delete_bucket(self).raise_if_not(Net::HTTPNoContent)
      end

      def disable_logging
        Aliyun::Oss::API.delete_logging(self).raise_if_not(Net::HTTPNoContent)
      end

      def enable_logging(target_bucket_name, log_prefix)
        Aliyun::Oss::API.enable_bucket_logging(self, target_bucket_name, log_prefix).raise_if_not(Net::HTTPOK)
      end

      def logging_status
        Aliyun::Oss::API.get_bucket_logging(self).to_logging_status
      end

      def disable_website_access
        Aliyun::Oss::API.delete_website(self).raise_if_not(Net::HTTPNoContent)
      end

      def enable_website_access(index_page, error_page)
        Aliyun::Oss::API.put_bucket_website(self, index_page, error_page).raise_if_not(Net::HTTPOK)
      end

      def website_access_status
        Aliyun::Oss::API.get_bucket_website(self).to_website_status
      end

      def set_acl(permission)
        Aliyun::Oss::API.put_bucket_acl(self, permission).raise_if_not(Net::HTTPOK)
      end

      def get_acl
        Aliyun::Oss::API.get_bucket_acl(self).to_acl_status
      end
    end
    
  end
end
