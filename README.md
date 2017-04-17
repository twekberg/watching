This repository is intended to be a replacement for the where.sh
script in the basic repository. The purpose of that script is to
locate resources used by specific users.

This version will be better than the previous one because resources
have been relocated to other hosts. At the time this was written the
wikis are split between web.labmed.washington.edu and
docs.labmed.uw.edu. In addition, sudo access was not managed.

basic installation
==================

Installation of the libraries is fairly simple. When developing, I
typically install the requirements to a virtualenv You'll need pip,
virtualenv, and setuptools.

Create a virtualenv::

  virtualenv hud-env
  source hud-env/bin/activate
  pip install -r requirements.txt

running
=======

./watch.yml -i hosts --ask-become-pass --extra-vars="users=kimthill" --user=ekberg
