module Aliyun
  module Oss

    module ConfigHelper
      def logger
        Aliyun::Oss.logger
      end

      def config
        Aliyun::Oss.config
      end

      def access_key_id
        Aliyun::Oss.config[:access_key_id]
      end

      def access_key_secret
        Aliyun::Oss.config[:access_key_secret]
      end

      def host
        Aliyun::Oss.config[:host]
      end

    end
  end
end
