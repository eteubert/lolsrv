# Show Off Lolcommits

## Requirements

- [ruby](http://www.ruby-lang.org/) >=1.9.3
- [mongodb](http://www.mongodb.org/)
- The git repository in question has to be a public repository at [github](https://github.com/)

## Setup

```
cp config.example.yml config.yml 
# edit config.yml, add the repository (e.g. eteubert/lolserver)

bundle install

# start mongodb
mongod

# start sinatra app
ruby index.rb
```

## Usage

Receives and displays images from `lolcommits` project.
