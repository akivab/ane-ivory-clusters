from django.utils import simplejson as json
import sys

def csv2json(csv_file):
    """Converts a CSV file to a JSON file for use in webpage.
    
    Input:
    first line: key1, key2, key3
    all others: val1, val2, val3
    
    Ouput:
    { key1: val1, key2: val2, key3: val3 },
    { key1: ... }
    """
    page = csv_file.split("\n")
    first = page[0]
    #print first
    page = page[1:]
    keys = [i.strip() for i in first.split(",")]
    kv = {}
    
    for row in page:
        if(len(row.strip())==0): continue
        vals = [i.strip() for i in row.split(",")]
        tmp = {}
        for count in xrange(len(keys)):
            tmp[keys[count]]=vals[count]
        kv[tmp[keys[0]]] = tmp

    return json.dumps(kv)

if __name__ == "__main__":
    if len(sys.argv) > 0:
        print csv2json(''.join(open(sys.argv[1],"r").readlines()))
    else:
        print "usage: python csv2json.py <csv_file>"
