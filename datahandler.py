import os
import logging

from google.appengine.ext import webapp
from google.appengine.ext import db
from google.appengine.api import users

from google.appengine.ext.webapp import template
from google.appengine.ext.webapp.util import run_wsgi_app
from csv2json import csv2json
  
def pretty_date(time=False):
    """
    Get a datetime object or a int() Epoch timestamp and return a
    pretty string like 'an hour ago', 'Yesterday', '3 months ago',
    'just now', etc
    """
    from datetime import datetime
    now = datetime.now()
    if type(time) is int:
        diff = now - datetime.fromtimestamp(time)
    elif isinstance(time,datetime):
        diff = now - time 
    elif not time:
        diff = now - now
    second_diff = diff.seconds
    day_diff = diff.days

    if day_diff < 0:
        return ''

    if day_diff == 0:
        if second_diff < 10:
            return "just now"
        if second_diff < 60:
            return str(second_diff) + " seconds ago"
        if second_diff < 120:
            return  "a minute ago"
        if second_diff < 3600:
            return str( second_diff / 60 ) + " minutes ago"
        if second_diff < 7200:
            return "an hour ago"
        if second_diff < 86400:
            return str( second_diff / 3600 ) + " hours ago"
    if day_diff == 1:
        return "Yesterday"
    if day_diff < 7:
        return str(day_diff) + " days ago"
    if day_diff < 31:
        return str(day_diff/7) + " weeks ago"
    if day_diff < 365:
        return str(day_diff/30) + " months ago"
    return str(day_diff/365) + " years ago"
          
class Data(db.Model):
    filename = db.StringProperty()
    data = db.TextProperty()
    updated = db.DateTimeProperty(auto_now_add=True)
    
    @classmethod
    def get_file(cls, filename):
        data = Data.gql("WHERE filename=:1 ORDER BY updated DESC LIMIT 1",filename).get()
        return data
    
class DataHandler(webapp.RequestHandler):
    def __init__(self):
        self.files = ["description"] + ["posterior_factorized_k%d"%i for i in xrange(2,6)]
    def validateUser(self):
        return users.is_current_user_admin()

    def analyzeCSV(self):
        filename = self.request.get("filename")
        if(filename not in [i+".csv" for i in self.files]):
            return "%s isn't an acceptable file." % filename
        d = self.request.get("delete")
        if(d == "1"):
            f1 = Data.gql("WHERE filename=:1 ORDER BY updated DESC", filename).get()
            f2 = Data.gql("WHERE filename=:1 ORDER BY updated DESC", filename[:-4]+".json").get()
            t = pretty_date(f1.updated)
            f1.delete()
            f2.delete()
            return "Deleted last version of %s from %s" % (filename, t)
        
        data = self.request.get("datafile")
        lastFile = Data.gql("WHERE filename=:1 ORDER BY updated DESC",filename).get()
        lastFirstLine = lastFile.data.split("\n")
        thisFirstLine = data.split("\n")
        if(thisFirstLine[0].strip() != lastFirstLine[0].strip()):
            return "%s doesn't match %s as keys for %s" % (thisFirstLine[0], lastFirstLine[0], filename)
        
        new_csv = Data(filename=filename, data=db.Text(data))
        new_json = Data(filename=filename[:-4]+".json", data=db.Text(csv2json(data)))
        new_csv.put()
        new_json.put()
        return "Added file to table!"
    def getGreeting(self):
        user = users.get_current_user()
        
        if user:
            greeting = ("Welcome, %s! (<a href=\"%s\">sign out</a>)" %
                        (user.nickname(), users.create_logout_url("/data/upload")))
        else:
            greeting = ("<a href=\"%s\">Sign in or register</a>." %
                        users.create_login_url("/data/upload"))

        return greeting

    def post(self):
        template_values = {}
        if self.validateUser():
            template_values['complete'] = self.analyzeCSV()
        else:
            template_values['complete'] = "User not admin."
        template_values['greeting'] = self.getGreeting()
        template_values['dates'] = self.getDates()
        path = os.path.join(os.path.dirname(__file__), 'upload.html')
        self.response.out.write(template.render(path, template_values))

    def getDates(self):
        dates = {}
        for f in self.files:
            csv = Data.gql("WHERE filename=:1 ORDER BY updated DESC", "%s.%s" % (f, "csv")).get()
            if csv:
                dates[f] = pretty_date(csv.updated)
            else:
                dates[f] = "Never."
        return dates

    def get(self):
        """We show info about current data files"""
        dates = self.getDates()
        template_values = {}
        template_values['greeting'] = self.getGreeting()
        template_values['dates'] = dates
        path = os.path.join(os.path.dirname(__file__), 'upload.html')
        self.response.out.write(template.render(path, template_values))

class MainHandler(webapp.RequestHandler):
    def get(self):
        path = self.request.path[6:]
        to_return = Data.get_file(path) 
        
        logging.info("Found file" if to_return else "Adding file")
        if not to_return:
            url = 'old_data/%s' % path
            datafile = os.path.join(os.path.dirname(__file__), url)
            to_return = Data(filename=path, data=''.join(open(datafile, "r").readlines()))
            to_return.put()
        self.response.headers['Content-Type'] = "application/json"
        self.response.out.write(to_return.data)

application = webapp.WSGIApplication([('/data/upload', DataHandler),
                                      ('/data/.*', MainHandler)
                                     ], debug=True)

def main():
    run_wsgi_app(application)

if __name__ == '__main__':
    main()
