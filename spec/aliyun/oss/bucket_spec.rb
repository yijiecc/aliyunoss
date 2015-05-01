require 'rspec'
require 'aliyun/oss'

describe Aliyun::Oss::Bucket do

  before :all do
    Aliyun::Oss.configure_with('spec/aliyun/oss/aliyun-config.yml')
  end

  before :each do
    @bucket_name = 'aliyun-oss-gem-api-test'
    @location = 'oss-cn-hangzhou'
    @bucket = Aliyun::Oss::Bucket.all.select {|b| b.name == @bucket_name} .first
  end
  
  it 'should create a bucket' do
    bucket = Aliyun::Oss::Bucket.create(@bucket_name, @location)
    expect(bucket).to_not be_nil
  end

  it 'should list all buckets' do
    buckets = Aliyun::Oss::Bucket.all
    selected = buckets.select {|b| b.name == @bucket_name}
    expect(selected.size).to eq(1)
  end

  it 'should list files on server' do
    expect(@bucket.list_files).to_not be_nil
  end
  
  it 'should upload data to server' do    
    files = ['test-1.png','test-2.png','test-3.png'].map {|f|  File.join(__dir__, f)}
    files.each do |f|
      data = IO.read(f)
      @bucket.upload(data, "/" + f[/test-\d\.png/], 'Content-Type'=>'image/png')
    end    
  end

  it 'should upload data to server in multipart way' do
    path = '/multi-part-test.dat'
    @bucket.multipart_upload_initiate(path)
    
    10.times do
      @bucket.multipart_upload( Random.new.bytes(1024 * rand(100..300)) )
    end

    @bucket.multipart_upload_complete
  end

  it 'should copy data in multipart way' do
    pending 'I get Forbidden using x-oss-copy-source-range'
    source_path = '/multi-part-test.dat'
    source_object = @bucket.list_files.select {|f| '/' + f['key'] == source_path} .first
    source_size = source_object['size'].to_i

    target_path = '/multi-part-copy.dat'
    @bucket.multipart_upload_initiate(target_path)
    @bucket.multipart_copy_from(@bucket, source_path, 1024*100, "bytes=0-#{1024*100-1}")
    @bucket.multipart_upload_complete    
  end
  
  it 'should download file from server' do
    ['/test-1.png','/test-2.png','/test-3.png'].each do |path|
      remote_data = @bucket.download(path)
      local_data = IO.read(File.join(__dir__, path))
      md5 = OpenSSL::Digest::MD5
      expect(md5.digest(remote_data)).to eq(md5.digest(local_data))
    end
  end

  it 'should delete file on server' do
    ['/test-1.png','/test-2.png','/test-3.png', '/multi-part-test.dat', '/multi-part-copy.dat'].each do |path|
      @bucket.delete(path)
    end
  end

  it 'should get and modify logging status' do
    @bucket.enable_logging('aliyun-oss-gem-api-test', 'access_log')
    sleep(2)
    expect(@bucket.logging_status['target_bucket']).to eq('aliyun-oss-gem-api-test')
    expect(@bucket.logging_status['target_prefix']).to eq('access_log')
    @bucket.disable_logging
  end

  it 'should get and modify website access status' do
    @bucket.enable_website_access('index.html','error.html')
    sleep(2)
    expect(@bucket.website_access_status['index_page']).to eq('index.html')
    expect(@bucket.website_access_status['error_page']).to eq('error.html')
    @bucket.disable_website_access
  end

  it 'should get and set access control list' do
    @bucket.set_acl('public-read')
    sleep(2)
    expect(@bucket.get_acl).to eq('public-read')
    @bucket.set_acl('private')
  end

  it 'should delete specified bucket' do
    @bucket.multipart_pending.each do |task|
      @bucket.multipart_abort(task['path'], task['upload_id'])
    end
    
    @bucket.delete!
    expect {Bucket.new(:name=> 'bucket_not_exist').delete!}.to raise_error
  end
  
end
