require 'rspec'
require 'aliyun/oss'

describe Aliyun::Oss::API do

  before :all do
    Aliyun::Oss.configure_with('spec/aliyun/oss/aliyun-config.yml')
#    Aliyun::Oss.configure(:log_level=> 'debug')
    bucket_name = 'aliyun-oss-gem-api-test'
    response = Aliyun::Oss::API.put_bucket(bucket_name)
    expect(response).to be_a(Net::HTTPOK)
  end

  before :each do
    @api = Aliyun::Oss::API
    @bucket = Aliyun::Oss::Bucket.new(name: 'aliyun-oss-gem-api-test', location: 'oss-cn-hangzhou')
  end

  it 'should get bucket list using GetService api' do
    response = @api.list_bucket
    expect(response).to be_a(Net::HTTPOK)
  end

  it 'should disable bucket logging' do
    expect(@api.delete_logging(@bucket)).to be_a(Net::HTTPNoContent)
  end
  
  it 'should disable bucket website access' do
    expect(@api.delete_website(@bucket)).to be_a(Net::HTTPNoContent)
  end

  it 'should list objects in bucket' do
    expect(@api.list_object(@bucket)).to be_a(Net::HTTPOK)
  end

  it 'should get bucket acl' do
    response = @api.get_bucket_acl(@bucket)
    expect(response).to be_a(Net::HTTPOK)
    xml = Nokogiri::XML(response.body).xpath('//Grant')
    expect(xml.count).to be >= 1
  end

  it 'should get bucket location' do
    response = @api.get_bucket_location(@bucket)
    expect(response).to be_a(Net::HTTPOK)
    node = Nokogiri::XML(response.body).xpath('//LocationConstraint')[0]
    expect(node.content).to eq('oss-cn-hangzhou')
  end

  it 'should get bucket logging status' do
    response = @api.get_bucket_logging(@bucket)
    expect(response).to be_a(Net::HTTPOK)
    expect(response.body).to include('BucketLoggingStatus')
  end

  it 'should get bucket logging status' do
    response = @api.get_bucket_website(@bucket)
    expect(response).to be_a(Net::HTTPNotFound)
  end

  it 'should correctly set bucket acl permission' do
    expect(@api.set_bucket_acl(@bucket, 'public-read')).to be_a(Net::HTTPOK)
    expect(@api.set_bucket_acl(@bucket, 'public-read-write')).to be_a(Net::HTTPOK)
    expect(@api.set_bucket_acl(@bucket, 'private')).to be_a(Net::HTTPOK)
  end

  it 'should enable and disable bucket logging func' do
    expect(@api.disable_bucket_logging(@bucket)).to be_a(Net::HTTPOK)    
    expect(@api.enable_bucket_logging(@bucket, @bucket.name, 'logtest-')).to be_a(Net::HTTPOK)
  end

  it 'should set bucket website access configuration' do
    expect(@api.set_bucket_website(@bucket, 'index.html','error.html')).to be_a(Net::HTTPOK)
  end

  it 'should upload file' do
    files = ['test-1.png','test-2.png','test-3.png'].map {|f|  File.join(__dir__, f)}
    files.each do |f|
      data = IO.read(f)
      response = @api.put_object(@bucket, "/" + f[/test-\d\.png/], data, 'Content-Type'=>'image/png')
      expect(response).to be_a(Net::HTTPOK)
    end
  end

  it 'should copy object' do
    sources = ['/test-1.png','/test-2.png','/test-3.png']
    sources.each do |source_path|
      response = @api.copy_object(@bucket, source_path, @bucket, "/copy-" + source_path[1,source_path.length-1])
      expect(response).to be_a(Net::HTTPOK)
    end
  end

  it 'should get object meta data' do
    expect(@api.head_object(@bucket, '/test-1.png')).to be_a(Net::HTTPOK)
  end

  it 'should get object from oss' do
    response = @api.get_object(@bucket, '/copy-test-1.png')
    file_name = File.join(__dir__, 'test-1.png')
    expect(response['Content-Length']).to eq(File.size(file_name).to_s)
    expect(response['Content-Type']).to eq('image/png')
  end

  it 'should delete object' do
    sources = ['/test-1.png','/test-2.png','/test-3.png']    
    sources.each do |path|
      expect(@api.delete_object(@bucket,path)).to be_a(Net::HTTPNoContent)
    end
  end

  it 'should delete multiple objects' do
    response = @api.delete_multiple_objects(@bucket, ['copy-test-2.png','copy-test-3.png', 'copy-test-1.png'])
    puts response.body
    expect(response).to be_a(Net::HTTPOK)
  end
  
  it 'should delete this bucket' do
   response = @api.delete_bucket(@bucket)
   expect(response).to be_a(Net::HTTPNoContent)    
  end
  
end

