require 'rspec'
require 'aliyunoss'
require 'spec_helper'

describe Aliyun::Oss::Bucket do

  before :all do
    Aliyun::Oss.configure_with('spec/aliyunoss/config/aliyun-config.yml')
    Aliyun::Oss.configure(logger: Logger.new(STDOUT))
    @bucket_name = "aliyunoss-gem-test-#{rand.to_s.delete('0.')}"
    @location = 'oss-cn-beijing'
    @bucket = Aliyun::Oss::Bucket.new( location: @location, name: @bucket_name)
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
    files = ['test-1.png','test-2.png','test-3.png'].map {|f|  File.join(__dir__, 'png',f)}
    files.each do |f|
      data = IO.read(f)
      @bucket.upload(data, "/" + f[/test-\d\.png/], 'Content-Type'=>'image/png')
    end
  end

  it 'should generate share url' do
    url = @bucket.share("/test-1.png")
    data = Net::HTTP.get(URI(url))
    expect(data.length).to eq(File.open( File.join(__dir__, "png", "test-1.png")).size)
  end

  it 'should generate direct upload headers' do
    file = File.join(__dir__, 'png', 'test-1.png')
    md5 = OpenSSL::Digest::MD5
    checksum = Base64.encode64(md5.digest(IO.read(file))).strip
    headers = @bucket.direct_upload_headers('/test-1.png', 
                                            filename: 'test-1.png',
                                            content_type: 'image/png',
                                            content_length: IO.read(file).bytesize,
                                            checksum: checksum,
                                            custom_metadata: {})
    
    # Now let's upload using these headers
    uri = URI("https://#{@bucket.name}.#{@bucket.location}.aliyuncs.com/test-1.png")
    request = Net::HTTP::Put.new(uri)
    headers.each_pair { |k,v| request[k] = v }
    request.body = IO.read(file)

    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      response = http.request(request)
      expect(response.code.to_s).to eq('200')
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
      local_data = IO.read(File.join(__dir__, 'png', path))
      md5 = OpenSSL::Digest::MD5
      expect(md5.digest(remote_data)).to eq(md5.digest(local_data))
    end
  end

  it 'get file info from server' do
    path = '/test-1.png'
    file_info = @bucket.get_file_info(path)
    expect(file_info['server']).to eq('AliyunOSS')
    expect(file_info['content-length']).to eq('127759')
  end

  it 'cannot get file info if file not existed' do
    path = '/test-8.png'
    expect(@bucket.exist?(path)).to be false

    path = '/test-3.png'
    expect(@bucket.exist?(path)).to be true
  end

  it 'get public url for file' do
    path = '/test-3.png'
    expect(@bucket.public_url(path)).to eq("https://#{@bucket_name}.oss-cn-beijing.aliyuncs.com/test-3.png")
  end

  it 'should delete file on server' do
    ['/test-1.png','/test-2.png','/test-3.png', '/multi-part-test.dat', '/multi-part-copy.dat'].each do |path|
      @bucket.delete(path)
    end
  end

  it 'should get and modify logging status' do
    @bucket.enable_logging(@bucket_name, 'access_log')
    status = @bucket.logging_status
    # it seems that changes do not take effect immediately
    # aliyun return loggint enabled status but without target_prefix
    # so we retry
    status = @bucket.logging_status
    status = @bucket.logging_status if status.count == 0
    status = @bucket.logging_status if status.count == 0
    expect(status['target_bucket']).to eq(@bucket_name)
    expect(status['target_prefix']).to eq('access_log')
    @bucket.disable_logging
  end

  it 'should get and modify website access status' do
    @bucket.enable_website_access('index.html','error.html')
    retries = 0
    begin
      status = @bucket.website_access_status
    rescue
      retry if (retries+=1) <= 5
    end
    expect(status['index_page']).to eq('index.html')
    expect(status['error_page']).to eq('error.html')
    @bucket.disable_website_access
  end

  it 'should get and set access control list' do
    @bucket.set_acl('public-read')
    status = @bucket.get_acl
    status = @bucket.get_acl if status == 'private'
    status = @bucket.get_acl if status == 'private'
    expect(status).to eq('public-read')
    @bucket.set_acl('private')
  end

  it 'should delete specified bucket' do
    @bucket.multipart_pending.each do |task|
      @bucket.multipart_abort(task['path'], task['upload_id'])
    end
    
    @bucket.delete!
    expect {Aliyun::Oss::Bucket.new(:name=> 'bucket_not_exist').delete!}.to raise_error(SocketError)
  end
  
end
