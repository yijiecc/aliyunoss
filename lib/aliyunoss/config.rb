require 'yaml'
require 'logger'

class NullLogger < Logger
  def initialize(*args)
  end

  def add(*args, &block)
  end
end


module Aliyun
  module Oss

    @config = {
      :logger => nil,
      :host => 'aliyuncs.com',
      :access_key_id => nil,
      :access_key_secret => nil
    }

    @valid_config_keys = @config.keys

    def self.configure(opts = {})
      opts.each {|k,v| @config[k.to_sym] = v if @valid_config_keys.include?(k.to_sym)}
    end

    def self.configure_with(yaml_file)
      begin
        config = YAML::load(IO.read(yaml_file))
        configure(config)
      rescue Errno::ENOENT
        logger.warn("YAML configuration file couldn't be found. Using defaults.")
      rescue Psych::SyntaxError
        logger.warn("YAML configuration file contains invalid syntax. Using defaults.")
      end
    end

    def self.config
      @config
    end

    def self.logger
      @config[:logger] or (@null_logger ||= NullLogger.new)
    end
    
  end
end
