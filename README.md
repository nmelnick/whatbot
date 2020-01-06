Welcome to whatbot
==================

This bot was written purely as an exercise in futility, to try, desperately, to
replace the functionality of infobot without driving us insane. Part of that
goal has been accomplished, and so we leave it out there for the world to use.
Drop us a note if you decide to play with it. Maybe if we hit 1.0, we'll
actually write a few docs. This is really just a project for fun, so there
really isn't and hasn't been a rallying cry for more documentation and support
infrastructure, so, uh, there isn't.

Playing with whatbot
--------------------

It works. Grab it from github, copy over the example configuration, and edit it
to do what you want. We will try to wrap up some documentation by the time we
hit 1.0, but it may take some time.

*Perl 5.14.0 or higher is required to get started.* The easiest way to go is to
run one of the build_* scripts in the root directory to install dependencies of
each of the child modules.

Once the dependencies are installed, copy `conf/whatbot.conf-example` to
`conf/whatbot.conf` and edit to your liking. To work with whatbot on the console
without connecting to another service, start with `whatbot.conf-consoleexample`.

```
cpanm -n Module::Install inc::Module::Install
cpanm --installdeps --notest --with-recommends .
perl -Ilib bin/whatbot
```

More information
----------------

GitHub: http://github.com/nmelnick/Whatbot

Home: http://www.whatbot.org
