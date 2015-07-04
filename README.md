# Aliyun::Oss

Ruby gem for [Aliyun Open Storage Service (OSS)][1]. This gem implemented API from [references of Aliyun OSS-API][2].

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aliyunoss'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aliyunoss

## Usage

This gem provides high level interfaces which are built around class Bucket and low level interfaces which are wrappers for [OSS API][2].

### Load Access Key ID and Access Key Secret

Specify you access key and access secret before calling methods provided in this gem:

	Aliyun::Oss::configure(:access_key_id => 'access key id from aliyun', :access_key_secret => 'access secret from aliyun')

### Low Level Interfaces

Low level interfaces are simple wrappers for [OSS API][2], you send requests with specified parameters and receive responses with a Net::HTTPResponse object. All parameters listed in [OSS API][2] are needed for every request, and context info between requests is maintained by yourself. In order to tell whether a a request is success, check code and body of returned Net::HTTPResponse object.

All [OSS API][2] listed are implemented except [Post Object][3] and [CORS APIs][4].

List all the buckets:

	Aliyun::Oss::API.list_bucket

Upload data to specified bucket:

	bucket = Aliyun::Oss::Bucket.new(:name => 'bucket-name', :location => 'oss-cn-beijing')
	path = '/test.dat'
	data = Random.new.bytes(1024 * rand(100..300))
	Aliyun::Oss::API.put_object(bucket, path, data)

Download data from specified bucket:

	bucket = Bucket.new(:name => 'bucket-name', :location => 'oss-cn-beijing')
	path = '/test.dat'
	Aliyun::Oss::API.get_object(bucket, path)

For more usage, see API documentation generated by rdoc.

### High Level Interfaces

High level interface are built around class Bucket. You create a new bucket, and upload, download or delete files in it. When needed, responses are parsed to array, hash or object etc, thus more meaningful. Exceptions will be raised when request failed.

	# Create a bucket in OSS server
	bucket = Aliyun::Oss::Bucket.create('aliyun-oss-gem-api-test','oss-cn-hangzhou')
	
	# Upload a file
	filename = '/some/file'
	bucket.upload( IO.read(filename) )
	
	# List all files in this bucket, returns a Hash array containing files info
	files = bucket.list_files
	
	# Download a file, returns raw data
	data = bucket.download( '/some/path' )
	
For more usage, see API documentation generated by rdoc.	
	
## Testing

This gem use rspec for testing. Most of testing needs a valid access key id and access key secret, you should get these info from Aliyun.

Create a file named aliyun-config.yml in path rspec/aliyunoss/config, fill in valid access key id and access key secret and cotinue to test.

## Contributing

1. Fork it ( https://github.com/yijiecc/aliyunoss/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[1]: http://www.aliyun.com/product/oss
[2]: http://docs.aliyun.com/?spm=5176.383663.9.2.F8rxxr#/oss/api-reference/abstract
[3]: http://docs.aliyun.com/?spm=5176.383663.9.2.F8rxxr#/oss/api-reference/object&PostObject
[4]: http://docs.aliyun.com/?spm=5176.383663.9.2.F8rxxr#/oss/api-reference/cors&abstract
