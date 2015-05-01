require 'yaml'
require 'logger'

module Aliyun
  module Oss

    @config = {
      :log_level => 'info',
      :host => 'aliyuncs.com',
      :access_key_id => nil,
      :access_key_secret => nil
    }

    @_logger = nil

    @valid_config_keys = @config.keys

    def self.configure(opts = {})
      @_logger = nil
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
      unless @_logger
        @_logger ||= Logger.new(STDOUT)
        @_logger.level = Logger.const_get(@config[:log_level].upcase) rescue Logger::INFO        
      end
      @_logger
    end
    
  end
end
