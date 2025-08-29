A Ruby gem template based on the template generated with `bundle gem some-gem-name`

## (1) Create new repo from template

```sh
gh repo create your-name/your-new-gem-repo --public --template=omgreenfield/ruby-gem-template
```

## (2) Setup

- Ensure you have Ruby `>= 3.1.0` installed
- Run `bin/setup` to install dependencies

## (3) Development

- Add code to `lib/`
- Run `bin/console` to load your library in a `pry` session
- Run `rake -T` to see available tasks

## (4) Publishing

- Run `rake build` to build the gem
- Run `rake push` or `rake publish` to push to RubyGems
