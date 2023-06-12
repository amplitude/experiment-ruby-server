<p align="center">
  <a href="https://amplitude.com" target="_blank" align="center">
    <img src="https://static.amplitude.com/lightning/46c85bfd91905de8047f1ee65c7c93d6fa9ee6ea/static/media/amplitude-logo-with-text.4fb9e463.svg" width="280">
  </a>
  <br />
</p>

[![Gem Version](https://badge.fury.io/rb/amplitude-experiment.svg)](https://badge.fury.io/rb/amplitude-experiment)

# Experiment Ruby SDK
Amplitude Ruby Server SDK for Experiment.

> ⚠️ **Local evaluation process fork safety:** When using a `LocalEvaluationClient` and forking the process, you must call `#start` _after forking_ to update the flag configuration state on the new process. For example, in Puma, this means calling `#start` in the [`on_worker_boot` hook](https://www.rubydoc.info/gems/puma/Puma%2FDSL:on_worker_boot). 

## Installation
Into Gemfile from rubygems.org:
```ruby
gem 'amplitude-experiment'
```
Into environment gems from rubygems.org:
```ruby
gem install 'amplitude-experiment'
```
To install beta versions:
```ruby
gem install amplitude-experiment --pre
```

## Remote Evaluation Quick Start
```ruby
require 'amplitude-experiment'

# (1) Get your deployment's API key
apiKey = 'YOUR-API-KEY'

# (2) Initialize the experiment client
experiment = AmplitudeExperiment.initialize_remote(api_key)

# (3) Fetch variants for a user
user = AmplitudeExperiment::User.new(user_id: 'user@company.com', device_id: 'abcezas123', user_properties: {'premium' => true})

# (4) Lookup a flag's variant
# 
# To fetch asynchronous
experiment.fetch_async(user) do |_, variants|
  variant = variants['YOUR-FLAG-KEY']
  unless variant.nil?
    if variant.value == 'on'
      # Flag is on
    else
      # Flag is off
    end
  end
end

# To fetch synchronous
variants = experiment.fetch(user)
variant = variants['YOUR-FLAG-KEY']
unless variant.nil?
  if variant.value == 'on'
    # Flag is on
  else
    # Flag is off
  end
end
```

## Local Evaluation Quick Start

```ruby
require 'amplitude-experiment'

# (1) Get your deployment's API key
apiKey = 'YOUR-API-KEY'

# (2) Initialize the experiment client
experiment = AmplitudeExperiment.initialize_local(api_key)

# (3) Start the local evaluation client
experiment.start

# (4) Evaluate a user
user = AmplitudeExperiment::User.new(user_id: 'user@company.com', device_id: 'abcezas123', user_properties: {'premium' => true})
variants = experiment.evaluate(user)
variant = variants['YOUR-FLAG-KEY']
unless variant.nil?
  if variant.value == 'on'
    # Flag is on
  else
    # Flag is off
  end
end
```

## More Information
Please visit our :100:[Developer Center](https://www.docs.developers.amplitude.com/experiment/sdks/ruby-sdk/) for more instructions on using our the SDK.

See our [Experiment Ruby SDK Docs](https://amplitude.github.io/experiment-ruby-server/) for a list and description of all available SDK methods.

See our [Local Evaluation Repo](https://github.com/amplitude/experiment-evaluation) for more details about local evaluation binary logic.

## Need Help?
If you have any problems or issues over our SDK, feel free to [create a github issue](https://github.com/amplitude/experiments-ruby-server/issues/new) or submit a request on [Amplitude Help](https://help.amplitude.com/hc/en-us/requests/new).
