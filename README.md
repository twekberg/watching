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

  virtualenv watching-env
  source watching-env/bin/activate
  pip install -r requirements.txt

running
=======

./watch_part1.yml -i hosts --ask-become-pass -v --user ekberg

./watch_part2.yml -i hosts --ask-become-pass -v --user tekberg

The user is prompted for the UWNetIDs in part1. It is stored in the
file $HOME/watch_users.txt and read in part2. It only has to be
entered in part1.

Output is written to $HOME/watch_results.txt.
