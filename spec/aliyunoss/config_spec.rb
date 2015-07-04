require 'rspec'
require 'aliyunoss'
require 'spec_helper'

describe 'Aliyun::Oss Configuration' do

  before :each do
    config = Aliyun::Oss.config
    config[:log_level] = 'info'
    config[:access_key_id] = nil
    config[:access_key_secret] = nil
  end
  
  it 'should load default options' do
    default_config = Aliyun::Oss.config
    expect(default_config).to include(:log_level)
    expect(default_config).to include(:access_key_id)
  end

  it 'should accept configuration from #configure' do
    url = "http://bucket_name.region.aliyuncs.com"
    access_key = "access_key_from_aliyun"
    Aliyun::Oss.configure(:log_level => 'debug', :access_key_id => access_key, :not_used_para => "not used")
    config = Aliyun::Oss.config
    expect(config.keys).not_to include(:not_used_para)
    expect(config[:access_key_id]).to eq(access_key)
    expect(config[:log_level]).to eq('debug')    
  end

  it 'should load yaml config file if specified' do
    Aliyun::Oss.configure_with('spec/aliyunoss/config/aliyun-config.yml.sample')
    config = Aliyun::Oss.config
    expect(config[:access_key_id]).to eq('access key _id from aliyun')
  end

  it 'should load default configuration if incorrect yaml file specified' do
    Aliyun::Oss.configure_with('spec/aliyunoss/config/incorrect-config.yml')
    config = Aliyun::Oss.config
    expect(config[:access_key_id]).not_to eq('1234567890')    
  end
end
