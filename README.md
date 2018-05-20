# Aliyun::Oss

Ruby gem for [Aliyun Open Storage Service (OSS)][1]. This gem implemented API from [references of Aliyun OSS-API][2].

## Table of Contents

* [Installation](#installation)
* [Usage](#usage)
  * [Load Access Key ID and Access Key Secrete](#load)
  * [Get Log Messages](#setlog)
  * [Using Bucket API](#highlevel)
    * [List Buckets](#listbuckets)
	* [Create a Bucket](#newbucket)
	* [Open a Bucket](#openbucket)
	* [List Files In Bucket](#listfiles)
	* [Upload a File to Bucket](#uploadfile)
	* [Download a File from Bucket](#downloadfile)
	* [Share a File in Bucket](#sharefile)
	* [Delete a File in Bucket](#deletefile)
	* [Upload a Large File in Multipart Way](#uploadlargefile)
	* [Delete a bucket](#deletebucket)
	* [Enable/Disable Logging for bucket](#logging)
  * [Using Primitive API](#lowlevel)
* [Test](#test)
* [Contribute](#contribute)

## <a name="installation"></a>Installation

Add this line to your application's Gemfile:

```ruby
gem 'aliyunoss'
```

And then execute:

```ruby
$ bundle
```

Or install it yourself as:

```ruby
$ gem install aliyunoss
```

## <a name="usage"></a>Usage

This gem provides Bucket API which are built around class Bucket and Primitive API which are wrappers for [OSS API][2]. Most of time using Bucket API is OK except you find OSS API that I didn't implement.

### <a name="load"></a>Load Access Key ID and Access Key Secret

Specify you access key and access secret before calling methods provided in this gem:

```ruby
Aliyun::Oss::configure(:access_key_id => 'access key id from aliyun', :access_key_secret => 'access secret from aliyun')
```
	
When using this gem in a rails project, you can create a file named 'aliyunoss_key.rb' in RAILS\_ROOT/config/initializers, whose content is: 

```ruby
Aliyun::Oss::configure(:access_key_id => 'access key id from aliyun', :access_key_secret => 'access secret from aliyun')
```
	
Then you can use the following APIs anywhere.

### <a name="setlog"></a>Get Log Messages

Log message is prohibited by default, you can pass a logger instace to enable it:

```ruby
Aliyun::Oss::configure(:logger => Logger.new(STDOUT))
```

### <a name="highlevel"></a>Bucket API

Bucket API are built around class Bucket. You create a new bucket, and upload, download or delete files in it. When needed, responses are parsed to array, hash or object etc, thus more meaningful. Exceptions will be raised when request failed.

```ruby
# Create a bucket in OSS server
bucket = Aliyun::Oss::Bucket.create('aliyun-oss-gem-api-test','oss-cn-hangzhou')
	
# Upload a file
filename = '/some/file'
bucket.upload( IO.read(filename) )
	
# List all files in this bucket, returns a Hash array containing files info
files = bucket.list_files
	
# Download a file, returns raw data
data = bucket.download( '/some/path' )
```
	
#### <a name="listbuckets"></a>List all buckets

After correctly configuring your access key and secret, you can list all buckets:

```ruby
Aliyun::Oss::Bucket.all
```

The result is a Bucket array. Class Bucket has some simple attributes :

```ruby
class Bucket
  attr_accessor :location, :name, :creation_date, :domain, :extranet_endpoint, :intranet_endpoint
  # ...
end
```

#### <a name="newbucket"></a>Create a new bucket

You can create a new bucket using class method *create* of Bucket:

```ruby
bucket = Aliyun::Oss::Bucket.create(bucket_name, bucket_location)
```
	
Where *bucket_name* is a string, and *bucket_location* is an optional string parameter which defaults to 'oss-cn-hangzhou'. Other available bucket locations can be referenced [here][5]. This method return a new Bucket instance if success.

#### <a name="openbucket"></a>Open a bucket

There is no such opeartion as opening a bucket, but you can create a Bucket instance by:

```ruby
Aliyun::Oss::Bucket.new(name: 'bucket-name', location: 'oss-cn-beijing')
```

So you can continue to download or upload files using this Bucket instance.

#### <a name="listfiles"></a>List all files in an bucket

You can list all files in an bucket using instance method *list\_files* of a bucket:

```ruby
files  = bucket.list_files
```

The result is a array consisted of file objects which are parsed from xml reponse, eg.

```ruby
[
  { "key"=>"100f1a845046c189944dc8fd57bffbe390b90e3a.png",
    "last_modified"=>"2015-12-14T03:04:37.000Z",
    "e_tag"=>"\"B9072ECBBF4B06962517B3FD4090538E\"",
    "type"=>"Normal",
    "size"=>"49509",
    "storage_class"=>"Standard" },

{ "key"=>"11c5db2a88648d25da889a1d20687ec535a50905.jpg",
    "last_modified"=>"2015-12-14T08:03:54.000Z",
    "e_tag"=>"\"77618F54695C08E278ACBD7D9C63E521\"",
	"type"=>"Normal",
	"size"=>"491133",
	"storage_class"=>"Standard" }
]
```

#### <a name="uploadfile"></a>Upload a file to bucket

You can upload a file using instance method *upload* of a bucket, eg.

```ruby
data = IO.read('/local/path/of/file')
bucket.upload(data, '/remote/path/of/file') 
```

This will raise an exception unless success. A file in remote bucket can include some meta data, eg. when serving images, we often want Aliyun OSS server to return *Content-Type* header for http GET request. To acheive this effect, we have to add additional paramters when uploading file, eg.

```ruby
image = IO.read('/local/image')
bucket.upload(image, '/remote/image', 'Content-Type'=>'image/png')
```

#### <a name="downloadfile"></a>Download file from bucket

You can read content of a remote file using instance method *download* of a bucket, eg.

```ruby
raw_data = bucket.download('/remote/path/of/file')
```

where *raw_data* is body of a Net::HTTPResponse object.

#### <a name="sharefile"></a>Generate a sharing url of a remote file

If you set your bucket private for reading, others cannot access content of files in your bucket without valid access key and secret. But you won't give them access key or secret, instead you generate a sharing url for them to access your file:

```ruby
public_url = bucket.share('/remote/file')
```
	
This will generate a public url that can access some remote file. By default this url is only valid for 1 hour, you can change this behavior by adding the second paramter:

```ruby
public_url = bucket.share('/remote/file', 60 * 60 * 24)
```

where unit used is second, so that will be 1 day long.

#### <a name="deletefile"></a>Delete a file in the bucket

You can delete a remote file using instance method *delete* of a bucket, eg:

```ruby
bucket.delete('/remote/path/of/file')
```
	
It will return an Net::HTTPNoContent if file is deleted successfully OR file not found.

#### <a name="uploadlargefile"></a>Upload a large file in multipart way

When uploading a large file, using multipart way is preffered due to unreliable network condition. An multipart task consist of a sequence operations: *multipart\_upload\_initiate*, *multipart\_upload* and *multipart_upload_compelete*:

```ruby
bucket.multipart_upload_initiate('/remote/path/of/a/large/file')
    
10.times do
  bucket.multipart_upload( Random.new.bytes(1024 * rand(100..300)) )
end

bucket.multipart_upload_complete
```

#### <a name="deletebucket"></a>Delete a bucket

You can delete a bucket using instance method *delete!* of a bucket, eg:

```ruby
bucket.delete!
```

Exception will be raised unless bucket is empty.

#### <a name="logging"></a>Enable/Disable logging for a bucket

OSS can record access log for a bucket, you can toggle this function by:

```ruby
bucket.enable_logging('/remote/file/of/log', 'log_prefix')
```

Then all access log is recorded with prefix you specified with the second paramter, and stored in the path you specified by the first parameter.

Disable this function by:

```ruby
bucket.disable_logging
```

### <a name="lowlevel"></a>Primitive API

Primitive API are simple http wrappers for [OSS API][2], you send requests with specified parameters and receive responses with a Net::HTTPResponse object. All parameters listed in [OSS API][2] are needed for every request, and context information between requests is maintained by yourself. In order to tell whether a a request is success, check code and body of returned Net::HTTPResponse object.

All [OSS API][2] listed are implemented except [Post Object][3] and [CORS APIs][4].

List all the buckets:

```ruby
Aliyun::Oss::API.list_bucket
```

Upload data to specified bucket:

```ruby
bucket = Aliyun::Oss::Bucket.new(:name => 'bucket-name', :location => 'oss-cn-beijing')
path = '/test.dat'
data = Random.new.bytes(1024 * rand(100..300))
Aliyun::Oss::API.put_object(bucket, path, data)
```

Download data from specified bucket:

```ruby
bucket = Bucket.new(:name => 'bucket-name', :location => 'oss-cn-beijing')
path = '/test.dat'
Aliyun::Oss::API.get_object(bucket, path)
```

For more usage, see API documentation generated by rdoc.

## <a name="test"></a>Testing

This gem use rspec for testing. Most of testing needs a valid access key id and access key secret, you should get these info from Aliyun.

Create a file named aliyun-config.yml in path rspec/aliyunoss/config, fill in valid access key id and access key secret and cotinue to test.

## <a name="contribute"></a>Contributing

1. Fork it ( https://github.com/yijiecc/aliyunoss/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[1]: https://www.aliyun.com/product/oss?spm=5176.doc31870.416540.44.QdQVwH
[2]: https://help.aliyun.com/document_detail/31827.html?spm=5176.doc31817.6.564.Px1zOr
[3]: https://help.aliyun.com/document_detail/31849.html?spm=5176.doc31827.6.581.XDg3ZS
[4]: https://help.aliyun.com/document_detail/31870.html?spm=5176.87240.400427.34.vFnPt8
[5]: https://help.aliyun.com/document_detail/31837.html?spm=5176.doc31959.2.1.EpUpfD
