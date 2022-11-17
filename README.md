# README

A simple web API that receives requests from devices of readings recorded at arbitrary intervals and provides summary data

## How To Start ##
This was developed using an Ubuntu install on WSL on a Windows machine. If not on a linux machine, [this is a great guide](https://www.hanselman.com/blog/ruby-on-rails-on-windows-is-not-just-possible-its-fabulous-using-wsl2-and-vs-code) for installing WSL.

You will need rails 7.0.4 and ruby 3.1.2 - I'm using `rbenv` to install and set that version to global:
```
rbenv install 3.1.2
rbenv global 3.1.2
gem install bundler
```
Clone the repo, and run `bundle install` within the top directory.

Once you have those dependencies, you should be able to run `bin/rails s` to start the server and begin posting readings and viewing device reading information locally :)

You can also run the (small) test suite with `bin/rails test`

## HTTP endpoints ##
### POST	/readings(.:format)	###
```
curl --request POST \
  --url http://localhost:3000/readings \
  --header 'Content-Type: application/json' \
  --data '{
   "id":"36d5658a-6908-479e-887e-a949ec199272",
   "readings":[
      {
         "timestamp":"2021-05-28T16:08:15+01:00",
         "count":4
      },
      {
         "timestamp":"2021-05-29T16:09:15+01:00",
         "count":1
      }
   ]
}'
```

The curl example is for a supported payload of n readings per device, which returns a 201 created status.

If you post a payload with malformed or missing data, this endpoint will retun a 400 bad request with relevant error(s).

* id is required
* if a reading is provided, the timestamp must be iso8601
* if a reading is provided, the count must be an integer

### GET	/devices/:id(.:format) ###
```
curl --request GET \
  --url http://localhost:3000/devices/36d5658a-6908-479e-887e-a949ec199272
```

This curl example call will return summary data based on readings posted under a given device id. If you run it after the first example, you should get a response like: 
```json
{
	"id": "36d5658a-6908-479e-887e-a949ec199272",
	"last_reading": {
		"timestamp": "2021-05-29T16:09:15+01:00",
		"count": 1
	},
	"cumulative_count": 5
}
```

If no readings have been posted yet for a given device, get requests will still return successfully, but the `last_reading` and `cumulative_count` values will be null and 0 respectively.

* last_reading is the reading with the most recent timestamp, regardless of the order in which they were posted
* cumulative_count is the sum of readings count values for the indicated device

## Design Decisions ##

Since this was an exercise, and not using any database was stipulated, I generated the new project using the `--minimal`, `--api`, and `--skip-active-record` flag. To use rails validations, I had my model include ActiveModel, to try to meet as many of the desired requirements quickly.

For storing readings by device.id in memory without a global variable, I'm making use of the Rails memory_store cache.

With regards to handling potential duplicate payloads, I'm writing all valid posted data to the cache, after ensuring all timestamps are unique. In a real-world scenario, I would want to ask more questions about the expected data. I'm assuming with this approach that while we may receive duplicate payloads, we won't have multiple valid count values for a given timestamp per device. The benefit of this "upsert"-like approach is it keeps the business logic simpler and handles a lot of potential edge cases not mentioned in the spec while still respecting the provided requirements. For example, if we receive payloads that partially duplicate, we don't reject the new desired readings provided along with the duplicated ones.

I installed rubocop because I <3 rubocop.

While I considered breaking down the get requirements into multiple endpoints (e.g. device/{{uuid}}/count), returning device summary data as a single request seemed easiest for a consumer without knowing more about any client requirements.

## Opportunities to Improve ##

Oh boy, I have several.
