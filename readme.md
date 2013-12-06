# Show Off Lolcommits

## Requirements

- [ruby](http://www.ruby-lang.org/) >=1.9.3
- [mongodb](http://www.mongodb.org/)
- The git repository in question has to be a public repository at [github](https://github.com/)
- on your dev machine: [lolcommits](https://github.com/sebastianmarr/lolcommits) (forked, with `lolsrv` plugin)

## Setup

```
cp config.example.yml config.yml
# edit config.yml, add the repository (e.g. eteubert/lolserver)

bundle install

# start mongodb
mongod

# start sinatra app
rackup -p 9393
```

## Development
There's some tools that are helpful for development.  Do not run guard and shotgun at the same time.

```
shotgun
# Restarts the web server when ruby files are changed
```

## Usage

Receives and displays images from `lolcommits` project.
