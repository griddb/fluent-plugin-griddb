
## Installation
### Requirements
* Ruby version 2.1
* Fluentd version 1.0

### Install plugin from local source code
Download fluent-plugin-griddb plugin
```
$ cd fluent-plugin-griddb
$ gem build fluent-plugin-griddb.gemspec
$ gem install --force --local fluent-plugin-griddb-1.0.0.gem
```
## How to use
### Important note
Before connect to this plugin, event data must follows the GridDB below rules:
* Time type only support format YYYY-MM-DDThh:mm:ss.SSSZ
* The object JSON fields must be mapping with the columns in the container one by one about columns order and data type
* The column value which does not exist in object JSON must be filled by null

=> All of this can be achieved by using "filter_record_transformer" plugin.

#### Configuration Example 

Container schema:

column name|type
--------|------
col1|timestamp
col2|string
col3|integer

Assume following input is coming:

```js
griddb: {"author":"gs_admin","date":1537420099,"data":10}
griddb: {"author":"gs_admin","date":1537420100}
```

Use "filter_record_transformer" plugin to configure below:

```
<filter griddb>
  @type record_transformer
  renew_record true
  enable_ruby true
  <record> 
   col1 ${Time.at(record["date"]).strftime('%Y-%m-%dT%H:%M:%S.%LZ')}
   col2 ${record.has_key?("author") ? record["author"]: nil}
   col3 ${record.has_key?("data") ? record["data"]: nil}
  </record>
</filter>
```
In above example:

```
_col1 ${Time.at(record["date"]).strftime('%Y-%m-%dT%H:%M:%S.%LZ')}_ 
``` 
=> To convert time to GridDB time format

```
_col2 ${record.has_key?("author") ? record["author"]: nil}_ 
```
=> To auto fill value *null* when value is empty or underfine

Then result becomes as below:
```js
griddb: {"col1":"2018-09-20T12:08:19.000Z","col2":"gs_admin","col3":10}
griddb: {"col1":"2018-09-20T12:08:20.000Z","col2":"gs_admin","col3":null}
```
=> Note that input data in GridDB need to be put in correct columns order. Therefore, column 1 must before column 2.

### Parameters

param|value
--------|------
host|database host(require)
port|database port(default: 8080)
cluster|cluster name(require)
database|database name(require). Use only "public"
container|container name(require)
username|username(require)
password|password(require)

## Examples
Below is detail examples when using fluent-plugin-griddb in some scenarios.
### Configuration Example1 (not using buffer)

```
<match griddb>
   @type griddb
   host localhost
   port 8080
   cluster defaultCluster
   database public
   container container_1
   username admin
   password admin
</match>
```

Assume following input is coming:

```js
griddb: {"col1":"2018-09-20T12:08:21.112Z","col2":"gs_admin","col3":10}
griddb: {"col1":"2018-09-20T12:08:22.234Z","col2":"gs_admin","col3":20}
griddb: {"col1":"2018-09-20T12:08:23.098Z","col2":"gs_admin","col3":30}
```

Then following requests are sending:
``` js
http://localhost:8080/griddb/v2/defaultCluster/dbs/public/containers/container_1/rows
Request data:
[
  ["2018-09-20T12:08:21.112Z", "gs_admin", 10]
]

http://localhost:8080/griddb/v2/defaultCluster/dbs/public/containers/container_1/rows
Request data:
[
  ["2018-09-20T12:08:22.234Z", "gs_admin", 20],
]

http://localhost:8080/griddb/v2/defaultCluster/dbs/public/containers/container_1/rows
Request data:
[
  ["2018-09-20T12:08:23.098Z", "gs_admin", 30]
]
```

Then result becomes as below:

```
+-----+-----------+--------------------------+
|           time          |  author  | value |
+-----+-----------+--------------------------+
| 2018-09-20 12:08:21.112 | gs_admin |   10  |
| 2018-09-20 12:08:22.234 | gs_admin |   20  |
| 2018-09-20 12:08:23.098 | gs_admin |   30  |
+-----+-----------+--------------------------+
```

### Configuration Example2 (use buffer with chunk limit)
"chunk_limit_records" option allow buffer based on number of records.
Below configuration allow send 1 insert data request after receive 3 records

```
<match griddb_**>
   @type griddb
   host localhost
   port 8080
   cluster defaultCluster
   database public
   container container_1
   username admin
   password admin
   <buffer>
      chunk_limit_records 3
   </buffer>
</match>
```

Assume following input is coming:

```js
griddb_error  : {"col1":"2018-09-20T12:08:21.112Z","col2":"gs_admin","col3":10}
griddb_warning: {"col1":"2018-09-20T12:08:22.234Z","col2":"gs_admin","col3":20}
griddb_warning: {"col1":"2018-09-20T12:08:23.098Z","col2":"gs_admin","col3":30}
griddb_warning: {"col1":"2018-09-20T12:08:24.001Z","col2":"gs_admin","col3":40}

```

Then following request is sending first:

``` js
http://localhost:8080/griddb/v2/defaultCluster/dbs/public/containers/container_1/rows

Request data:
[
  ["2018-09-20T12:08:21.112Z", "gs_admin", 10],
  ["2018-09-20T12:08:22.234Z", "gs_admin", 20],
  ["2018-09-20T12:08:23.098Z", "gs_admin", 30],
]
```

Then result becomes as below:

```
+-----+-----------+--------------------------+
|           time          |  author  | value |
+-----+-----------+--------------------------+
| 2018-09-20 12:08:21.112 | gs_admin |   10  |
| 2018-09-20 12:08:22.234 | gs_admin |   20  |
| 2018-09-20 12:08:23.098 | gs_admin |   30  |
+-----+-----------+--------------------------+
```

If duplicate time then update author and value

### Configuration Example3 (use buffer with time limit)
"flush_interval" option allow buffer based on time interval. 
Below configuration allow send 1 insert data request each 10 seconds

```
<match griddb_**>
   @type griddb
   host localhost
   port 8080
   cluster defaultCluster
   database public
   container container_1
   username admin
   password admin
   <buffer>
      flush_interval 10
   </buffer>
</match>
```

Assume following input is coming:

```js
griddb_error  : {"col1":"2018-09-20T12:08:21.112Z","col2":"gs_admin","col3":10}
griddb_warning: {"col1":"2018-09-20T12:08:22.234Z","col2":"gs_admin","col3":20}
griddb_warning: {"col1":"2018-09-20T12:08:23.098Z","col2":"gs_admin","col3":30}
griddb_warning: {"col1":"2018-09-20T12:08:44.001Z","col2":"gs_admin","col3":40} // out of 10 seconds range

```

Then following request is sending after the first 10 seconds:

``` js
http://localhost:8080/griddb/v2/defaultCluster/dbs/public/containers/container_1/rows

Request data:
[
  ["2018-09-20T12:08:21.112Z", "gs_admin", 10],
  ["2018-09-20T12:08:22.234Z", "gs_admin", 20],
  ["2018-09-20T12:08:23.098Z", "gs_admin", 30],
]
```

Then result becomes as below:

```
+-----+-----------+--------------------------+
|           time          |  author  | value |
+-----+-----------+--------------------------+
| 2018-09-20 12:08:21.112 | gs_admin |   10  |
| 2018-09-20 12:08:22.234 | gs_admin |   20  |
| 2018-09-20 12:08:23.098 | gs_admin |   30  |
+-----+-----------+--------------------------+
```

### Configuration Example4 (use buffer with chunk limit and placeholders)
"${tag}" is a place holder for event "tag".
fluent plugin griddb only support placeholders in *container* parameter
Below configuration allow send insert request to multiple containers base on event "tag"

```
<match griddb_**>
   @type griddb
   host localhost
   port 8080
   cluster defaultCluster
   database public
   container ${tag}
   username admin
   password admin
   <buffer tag>
      chunk_limit_records 2
   </buffer>
</match>
```

Assume following input is coming:

```js
griddb_error  : {"col1":"2018-09-20T12:08:21.112Z","col2":"gs_admin","col3":100}
griddb_error  : {"col1":"2018-09-20T12:08:21.120Z","col2":"gs_admin","col3":200}
griddb_warning: {"col1":"2018-09-20T12:08:22.234Z","col2":"gs_admin","col3":20}
griddb_warning: {"col1":"2018-09-20T12:08:23.098Z","col2":"gs_admin","col3":30}
griddb_warning: {"col1":"2018-09-20T12:08:24.001Z","col2":"gs_admin","col3":40}
```

Then following request is sending:

``` js
http://localhost:8080/griddb/v2/defaultCluster/dbs/public/containers/griddb_error/rows

Request data:
[
  ["2018-09-20T12:08:21.112Z", "gs_admin", 100],
  ["2018-09-20T12:08:21.120Z", "gs_admin", 200]
]

http://localhost:8080/griddb/v2/defaultCluster/dbs/public/containers/griddb_warning/rows

Request data:
[
  ["2018-09-20T12:08:22.234Z", "gs_admin", 20],
  ["2018-09-20T12:08:23.098Z", "gs_admin", 30]
]
```

Then result becomes as below:

**container griddb_error**

```
+-----+-----------+--------------------------+
|           time          |  author  | value |
+-----+-----------+--------------------------+
| 2018-09-20 12:08:21.112 | gs_admin |  100  |
| 2018-09-20 12:08:21.120 | gs_admin |  200  |
+-----+-----------+--------------------------+
```

**container griddb_warning**

```
+-----+-----------+--------------------------+
|           time          |  author  | value |
+-----+-----------+--------------------------+
| 2018-09-20 12:08:22.234 | gs_admin |   20  |
| 2018-09-20 12:08:23.098 | gs_admin |   30  |
+-----+-----------+--------------------------+
```


### Configuration Example5 (multiple layer Json)
GridDB does not support layerer data.
Therefore, Json data with multiple layer will need to be flatten to 1 layer before insert to GridDB.
The flatten process can be achieve using "filter_record_transformer" plugin.
Below is example of input data from DStat to GridDB.

The configuration for griddb plugin is the same:

```
<match griddb_**>
   @type griddb
   host localhost
   port 8080
   cluster defaultCluster
   database public
   container container_1
   username admin
   password admin
   <buffer>
      chunk_limit_records 3
   </buffer>
</match>
```

Assume following input is coming:

```js
griddb_pc_status : {  
   "hostname":"localhost",
   "dstat":{  
      "total_cpu_usage":{  
         "usr":"9.813",
         "sys":"2.013",
         "idl":"87.527",
         "wai":"0.631",
         "hiq":"0.0",
         "siq":"0.016"
      }
   }
}

```

Before data is sent to GridDB, we need to flatten JSON data with "filter_record_transformer" plugin.
```
# we need to add this before griddb plugin
<filter griddb_**>
  @type record_transformer
  enable_ruby
  renew_record true
    <record>
        col1 ${time.strftime('%Y-%m-%dT%H:%M:%S.%LZ')}
        col2 ${(record.has_key?("dstat") && record["dstat"].has_key?("total_cpu_usage") && record["dstat"]["total_cpu_usage"].has_key?("usr"))?record["dstat"]["total_cpu_usage"]["usr"]:nil}
    </record>
</filter>

# input data is : griddb_pc_status : {"col1":"2019-04-05T14:28:22.918Z","col2":"9.813"}
<match griddb_**>
   @type griddb
   host localhost
   port 8080
   cluster defaultCluster
   database public
   container container_1
   username admin
   password admin
   <buffer>
      chunk_limit_records 3
   </buffer>
</match>
```

Then following request is sending first:

``` js
http://localhost:8080/griddb/v2/defaultCluster/dbs/public/containers/container_1/rows

Request data:
[
  ["2019-04-05T14:28:22.918Z", "9.813"]
]
```

Then result becomes as below:

```
+-----+-----------+-----------------+
|           time          |   usr   |
+-----+-----------+-----------------+
| 2019-04-05T14:28:22.918 |  9.813  |
+-----+-----------+-----------------+
```

If duplicate time then update author and value