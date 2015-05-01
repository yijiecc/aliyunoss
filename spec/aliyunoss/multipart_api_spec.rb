require 'rspec'
require 'aliyunoss'

describe Aliyun::Oss::API do

  before :all do
    Aliyun::Oss.configure_with('spec/aliyunoss/aliyun-config.yml')
    Aliyun::Oss.configure(:log_level=> 'debug')
    bucket_name = 'aliyun-oss-gem-api-test'
    response = Aliyun::Oss::API.put_bucket(bucket_name)
    expect(response).to be_a(Net::HTTPOK)
  end

  before :each do
    @api = Aliyun::Oss::API
    @bucket = Aliyun::Oss::Bucket.new(name: 'aliyun-oss-gem-api-test', location: 'oss-cn-hangzhou')
  end

  it 'should upload data in multipart way' do
    path = '/multi-part-test.dat'
    response = @api.multipart_upload_initiate(@bucket, path)
    expect(response).to be_a(Net::HTTPOK)

    upload_id = Nokogiri::XML(response.body).xpath('//UploadId')[0].content
    expect(upload_id).to_not be_nil

    part_list = {}
    (1..10).each do |no|
      data = Random.new.bytes(1024 * rand(100..300))
      response = @api.multipart_upload_part(@bucket, path,upload_id, data, no)
      expect(response).to be_a(Net::HTTPOK)
      expect(response['ETag']).to_not be_nil
      expect(response['ETag']).to be_a(String)
      part_list[no] = response['ETag']
    end

    response = @api.multipart_upload_finished_parts(@bucket, path, upload_id)
    expect(response).to be_a(Net::HTTPOK)
    expect(response.body.include?('ListPartsResult')).to be true

    response = @api.multipart_upload_complete(@bucket, path, upload_id, part_list)
    expect(response).to be_a(Net::HTTPOK)
  end

  it 'should aboart uploading' do
    path = '/multi-part-test-aborted.dat'
    response = @api.multipart_upload_initiate(@bucket, path)
    expect(response).to be_a(Net::HTTPOK)

    upload_id = Nokogiri::XML(response.body).xpath('//UploadId')[0].content
    expect(upload_id).to_not be_nil

    data = Random.new.bytes(1024 * rand(100..300))

    response = @api.multipart_upload_part(@bucket, path, upload_id, data, 1)
    expect(response).to be_a(Net::HTTPOK)

    response = @api.multipart_upload_abort(@bucket, path, upload_id)
    expect(response).to be_a(Net::HTTPNoContent)
  end

  it 'should copy object from bucket in multipart way' do
    path = '/copy-multi-part-test.dat'
    response = @api.multipart_upload_initiate(@bucket, path)
    expect(response).to be_a(Net::HTTPOK)

    upload_id = Nokogiri::XML(response.body).xpath('//UploadId')[0].content
    expect(upload_id).to_not be_nil

    data = Random.new.bytes(1024 * rand(100..300))

    response = @api.multipart_upload_from_copy(upload_id, @bucket, '/multi-part-test.dat',
                                               @bucket, path, 1, 1024*500)
    expect(response).to be_a(Net::HTTPOK)

    response = @api.multipart_upload_abort(@bucket, path, upload_id)
    expect(response).to be_a(Net::HTTPNoContent)
  end

  it 'should delete uploaded file' do
    expect(@api.delete_object(@bucket,'/multi-part-test.dat')).to be_a(Net::HTTPNoContent)    
  end

  it 'should list unfinished multipart upload task' do
    response = @api.multipart_upload_unfinished_task(@bucket)
    expect(response).to be_a(Net::HTTPOK)

    # cancel all unfinished task
    nodes = Nokogiri::XML(response.body).xpath('//Upload')
    nodes.each do |node|
      path = '/' + node.xpath('Key').first.content
      id = node.xpath('UploadId').first.content
      response = @api.multipart_upload_abort(@bucket, path, id)
      expect(response).to be_a(Net::HTTPNoContent)
    end
  end

  it 'should delete this bucket' do
   response = Aliyun::Oss::API.delete_bucket(@bucket)
   expect(response).to be_a(Net::HTTPNoContent)
  end
  
end
