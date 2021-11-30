#!/usr/bin/env python
"""
Combine the uwnetid watch_results.txt parts into one dict.
"""

import sys
# If there are input errors, run from the command line and use simplejson
# which gives better error messages than json.
#import simplejson as json
import json

def main(in_filename):
    with open(in_filename) as in_file:
        watch_results = json.load(in_file)
    results = dict()
    for watch_result in watch_results:
        uwnetid = watch_result['uwnetid']
        if uwnetid not in results:
            results[uwnetid] = dict()
        for field in watch_result.keys():
            if field != 'uwnetid':
                results[uwnetid][field] = watch_result[field]
    print(json.dumps(results, sort_keys=True,
                     indent=4, separators=(',', ': ')))

if __name__ == '__main__':
    main(sys.argv[1])
