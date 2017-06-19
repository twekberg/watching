"""
Checks to see if the user is a member of the bitbucket team uwlabmed.

Usage:
  python backup_data.sh UWNetID json_filename

If the user is found then the uwnetid and bitbucket username are printed.

Exit status:
  0 - user was found
  1 - user was not found
  2 - usage error

It is assumed that this command has already been executed:

  wget --quiet --output-document=/tmp/uwlabmed.json \
      https://api.bitbucket.org/2.0/teams/uwlabmed/members?pagelen=100

Whatever output-document is specified, that is passed in to this program.
"""

import json
import sys

# Map a UWNetID to a bitbucket name. Most of the time they are the same.
# These are the exceptions.
bb_username_map = dict([('ngh2', 'nhoffman'),
                    ('tland9', 'tyleraland'),
                    ('nguyenda',  'dnguyen3'),
                    ('huqnp', 'nabiha'),
                    ('ashep', 'ashepuw'),
                    ('cgriffin', 'cathygriffin'),
                    ('pcm10', 'pcmathias'),
                    ('konnick', 'ekonnick')])

def main(uwnetid, json_filename):
    with open(json_filename) as json_file:
        members = json.load(json_file)
    users = dict()
    # Convert list to dict.
    for user in members['values']:
        users[user['username']] = user
    bb_username = bb_username_map[uwnetid] if uwnetid in bb_username_map else uwnetid
    if bb_username in users:
        print '%s %s' % (uwnetid, bb_username)
        exit(0)
    else:
        exit(1)

if __name__ == '__main__':
    try:
        main(sys.argv[1], sys.argv[2])
    except IndexError:
        print "Usage: python where-bitbucket.py UwNetID json_filename"
        exit(2)
