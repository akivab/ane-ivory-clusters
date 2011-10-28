import json
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
    
    page = open(csv_file, "r").readlines()

    first = page[0]
    page = page[1:]
    keys = [i.strip() for i in first.split(",")]
    kv = {}
    count = 0
    for row in page:
        print row.strip()
        vals = [i.strip() for i in row.split(",")]
        print vals
        tmp = {}
        for count in xrange(len(keys)):
            if len(vals) > count and vals[count] != "":
                tmp[keys[count]]=vals[count]
        if keys[0] in tmp:
            kv[keys[0]] = tmp
        else:
            kv[count] = tmp
            count+=1
    
    idx = csv_file.find(".csv")
    if idx > -1:
        to_write = "%s.json" % csv_file[:idx]
        k = open(to_write, "w")
        k.write(json.dumps(kv))
    else:
        print json.dumps(kv)

if __name__ == "__main__":
    if len(sys.argv) > 0:
        csv2json(sys.argv[1])
    else:
        print "usage: python csv2json.py <csv_file>"
