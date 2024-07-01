# ChangeTheSubject

This gem is currently used to mask outdated Library of Congress Subject Headings in two different public access catalogs - [Princeton University Library Catalog](https://catalog.princeton.edu/) and [Princeton University Library Finding Aids](https://findingaids.princeton.edu/).

The code for this gem started in the [bibdata codebase](https://github.com/pulibrary/bibdata), the application that prepares metadata for use by the Catalog, and you can [see the gem's earlier history there](https://github.com/pulibrary/bibdata/commits/590d2437126150d66e40393724f9e11ba95c3328/marc_to_solr/lib/change_the_subject.rb).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'change_the_subject'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install change_the_subject

## Usage
The main api of the gem is the `ChangeTheSubject.fix` method, which takes an array of subject terms, compares them to the configuration (the default is in `config/change_the_subject.yml`), and replaces the configured terms. You can see how Bibdata uses the gem in its [traject_config.rb](https://github.com/pulibrary/bibdata/blob/main/marc_to_solr/lib/traject_config.rb).

```ruby
original_subjects = ["Something problematic", "Something not problematic"]
subjects = ChangeTheSubject.fix(subject_terms: original_subjects)
# outputs ["Something not problematic from config", "Something not problematic"]
```

The `ChangeTheSubject.fix` method also takes an optional `separators` argument, which you can [see in use in Pulfalight's implementation for eads](https://github.com/pulibrary/pulfalight/blob/main/lib/pulfalight/traject/ead2_config.rb).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Running the tests

```
bundle exec rspec
```

## Contributing
The configuration for this gem is managed by the Inclusive and Reparative Metadata Working Group (IRMWG). Send questions or comments about the configuration to harmfullanguage@princeton.libanswers.com.

Bug reports and pull requests are welcome on GitHub at https://github.com/pulibrary/change_the_subject.
