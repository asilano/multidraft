multidraft [![Build Status](https://travis-ci.org/asilano/multidraft.png?branch=master)](https://travis-ci.org/asilano/multidraft)[![Coverage Status](https://coveralls.io/repos/asilano/multidraft/badge.png)](https://coveralls.io/r/asilano/multidraft)[![Code Climate](https://codeclimate.com/github/asilano/multidraft.png)](https://codeclimate.com/github/asilano/multidraft)
==========

A multi-purpose draft server, interfacing with alextfish/multiverse

----

There's not much code here at the moment, just a bare space for design conversations in the repo [wiki](https://github.com/asilano/multidraft/wiki).

But trust me - there will be code. And it will be epic.

----

Setting up on Windows
----

1. If you haven't already, or are a long way out of date, download and install Rails etc. from [RailsInstaller](http://railsinstaller.org).
2. If you haven't already, download and install [PostgreSQL](http://www.postgresql.org/download/windows/)
3. Clone (or fork) this repo - `git clone git@github.com:asilano/multidraft.git`
4. Install the bundle, but not the production group (unicorn won't install on Windows) - `bundle --without production`
5. Make sure postgres is running, and start up a session - `psql`. Depending on how you set it up, you may need to specify the user - e.g. `psql -U postgres`
6. Create a new database user for multidraft - `CREATE USER multidraft SUPERUSER LOGIN PASSWORD 'multidraft';`
7. Create the dev and test databases; `bundle exec rake db:setup; bundle exec rake db:test:prepare`
8. Optionally, download and start using [AnsiCON](https://github.com/adoxa/ansicon), for coloured test output
9. Optionally, start spork (which seems to work this time!) - `spork`
10. Run those tests - `bundle exec rake spec` or `rspec spec`