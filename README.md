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

First, parts of the current implementation that are known issues:
1. *device.id* - the exercise directions specify that payloads can be malformed, and I assume that includes the id. Right now there is a check for id presence, but nothing to validate the format. If you send a string or number as the id instead of a UUID, it will treat it as accepted input and store any related data to a new device with that id.
2. *individual malformed readings along with valid ones in payload* - if only some readings are malformed/invalid, the entire payload is currently rejected. It wouldn't be too hard to change this to allow a user to save only valid payloads, I just ran out of time

Things I would immediately change or add:
1. I had actually never implemented a rails API without a database/active support, and I'm not sure using the cache was the best choice. However, if I was going to move forward supporting this approach, I would want to change my environment config. I currently have `perform_caching` enabled for dev and test environments. It works with existing tests, but really I should have created a test_helper for working with the cache (and managed things like setting up and tearing down stored values around sets of tests).
2. Need to add API call tests. I have model tests, because I prioritized that to validate logic as I wrote it, but I would want controller tests that validate the expected respones statuses and response bodies with example payloads. I also just went with very minimal test setup; I'd love to use RSpec and look into other test libraries to make supporting tests easier going forward.
3. I added the Rubocop gem and used it to keep my additions formatted, but there are failing lint issues just with the generated setup. Would go through and either exclude those with a comment likely, or make minor modifications to the issues so that rubocop could be used.

Production considerations (basically other things I know are missing if this were a solution I were writing to support in prod):
1. Logging of calls
2. Exception monitoring, like Honeybadger or Bugsnag
3. Honestly, if I were developing this for prod at a company that uses cloud services and depending on the frequency with which devices transmit readings, I'd probably want to setup my endpoints in an API Gateway. I'd love to have the post cal that receives readings actually hit a lambda or a function, and then write that payload to a queue assuming it validates - then you could have a background worker process readings (using ActiveJob, shoryuken).
4. Some basic metrics (e.g. counters for number of calls, a way to see the percentage of calls that are failing)
5. If we used a database, having an understanding of the business questions this API should answer long term. With a schema like this, often only recent details are cared about, so starting with a policy of archiving summary data and automatically deleting or migrating old data can be really helpful. It's easier to expand duration over time if there is a need I've found, then to try to communicate limits on data lifecycle down the line. Not sure if this would only be relevant, but another thought I had!
