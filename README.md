# SafetyPin

Interact with a [JCR Content Repository](http://jackrabbit.apache.org/jcr-api.html) using the Ruby code you love.

Originally made to turn long, manually node editing tasks into fast, script-able moments.

## Installation

**This gem requires [JRuby](http://jruby.org/) to run**

Add this line to your application's Gemfile:

    gem 'safety-pin'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install safety-pin

## Usage

You can interact with the JCR using Ruby code in ways you would expect:

```ruby
require 'safety-pin'
include SafetyPin

node = Node.find("/content") # returns node at path
node.child("foo")            # returns child by name
node.children                # returns array of children

node.properties                    # returns hash of unprotected properties
node.properties = {"bar" => "baz"} # replaces unprotected properties

node["foo"]         # returns value of property
node["foo"] = "bar" # assigns value to property

node.save    # saves changes to session
node.refresh # reloads node from JCR
```

## Interactive Shell

You can open an IRB with SafetyPin included and connected to a JCR instance:

```sh
$ rbenv global jruby-1.7.0-rc1 # make sure to use JRuby
$ gem install safety-pin
$ safety-pin -h http://localhost:4502
Username: # type username
Password: # type password
>> Node.find("/content")
=> #<SafetyPin::Node:0x146ccf3e>
>> # type whatever
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
