# RrxConfig


TODO: Delete this and the text below, and describe your gem

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/rrx_config`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add rrx_config

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install rrx_config

## Usage

This gem loads runtime application configuration from an external source

For example, with the JSON config

```json
{
  "some_config": {
    "value": "foo"
  },
  "other_config_value": "bar"
}
```

The config would be accessed like this:

```ruby
def my_code
  if RrxConfig.some_config.value == 'foo'
    do_something RrxConfig.other_config_value
  end
end
```

Configurations are stored as immutable Ruby `Data` objects. You can test for optional values:

```ruby
optional_stuff if RrxConfig.members.include?(:optional_thing)
deep_optional_stuff if RrxConfig.optional_thing.members.include?(:deep_thoughts)

# Root-level configs can also be tested with the xxxx? syntax
optional_stuff if RrxConfig.optional_thing?
```

### Environment

Set the `RRX_CONFIG` environment variable to the required JSON configuration

### AWS

Loads configuration from an AWS secret that contains the required JSON configuration. Recommended when deploying on AWS.
By default will use the implicit AWS context that is assigned by the instance role.

Set the `RRX_CONFIG_AWS_SECRET` to the name of the secret to read.

For local integration testing, set `RRX_AWS_PROFILE` to use local AWS credentials. The profile must have been
configured in the local AWS client (typically `~/.aws/credentials`).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rrx/rrx_config. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/rrx_config/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RrxConfig project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rrx_config/blob/main/CODE_OF_CONDUCT.md).
