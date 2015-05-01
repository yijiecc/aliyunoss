# coding: utf-8
require 'rspec'
require 'aliyunoss'

describe Aliyun::Oss::OssRequest do

  it 'should correctly calculate CanonicalizedOssHeader' do
    Aliyun::Oss.configure(:access_key_id => '44CF9590006BF252F707',
                          :access_key_secret => 'OtxrzxIsfpFjA7SwPzILwy8Bw21TLhquhboDYROV')
    req = Net::HTTP::Get.new(URI("http://" + Aliyun::Oss.config[:host] + "/nelson"))
    req["X-OSS-Meta-Author"] = "foo@bar.com"
    req["X-OSS-Magic"] = "abracadabra"
    req["Date"] = "Thu, 17 Nov 2005 18:49:58 GMT"
    req["Content-Type"] = "text/html"
    req["Content-MD5"] = "ODBGOERFMDMzQTczRUY3NUE3NzA5QzdFNUYzMDQxNEM="
    result = Aliyun::Oss::OssRequest.new(nil, '/').
             send(:canonicalized_oss_headers, req)
    expect(result).to eq("x-oss-magic:abracadabra\nx-oss-meta-author:foo@bar.com\n")
  end

  it 'should correctly calculate CanonicalResource' do
    bucket = Aliyun::Oss::Bucket.new(:name=>'BucketName',               
                                     :location=> 'oss-cn-hangzhou')
    path = '/ObjectName'
    queries = {"acl"=>nil, "uploadId"=>"UploadId",
               "response-content-type"=>"ContentType" }
    result = Aliyun::Oss::OssRequest.new(bucket, path, queries).
             send(:canonicalized_resource)
    expect(result).to eq("/BucketName/ObjectName?acl&response-content-type=ContentType&uploadId=UploadId")

    result = Aliyun::Oss::OssRequest.new(bucket, path).
             send(:canonicalized_resource)
    expect(result).to eq("/BucketName/ObjectName")
  end

  it 'should correctly calculate signature in Authorization header' do
    Aliyun::Oss.configure(:access_key_id => '44CF9590006BF252F707',
                          :access_key_secret => 'OtxrzxIsfpFjA7SwPzILwy8Bw21TLhquhboDYROV')
    bucket = Aliyun::Oss::Bucket.new(name: 'oss-example', location: 'oss-cn-hangzhou')
    oss_req = Aliyun::Oss::OssRequest.new(bucket, '/nelson')
    param = Net::HTTP::Put.new(oss_req.get_uri)
    param["X-OSS-Meta-Author"] = "foo@bar.com"
    param["X-OSS-Magic"] = "abracadabra"
    param["Date"] = "Thu, 17 Nov 2005 18:49:58 GMT"
    param["Content-Type"] = "text/html"
    param["Content-MD5"] = "ODBGOERFMDMzQTczRUY3NUE3NzA5QzdFNUYzMDQxNEM="
    result = oss_req.send(:signature, param)
    expect(result).to eq("26NBxoKdsyly4EDv6inkoDft/yA=")
  end
  
end
