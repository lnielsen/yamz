#!/usr/bin/python
from flask import Flask
from flask import Markup
from flask import render_template
from flask import request

import sys, MySQLdb as mdb
import seaice

## Connect to local MySQL databse. ## 

try: 

  config = seaice.get_config()
  
  sea = seaice.SeaIceDb( 'localhost', 
                          config.get('default', 'user'),
                          config.get('default', 'password'),
                          config.get('default', 'dbname')
                       )

except mdb.Error, e:
  print >>sys.stderr, "error (%d): %s" % (e.args[0],e.args[1])
  sys.exit(1)

print "ice: connection to database established."

## HTTP request handlers ##

app = Flask(__name__)

@app.route("/")
def index():
  return render_template("index.html")

@app.route("/about")
def about():
  return render_template("about.html")

@app.route("/contact")
def contact():
  return render_template("contact.html")

@app.route("/browse")
def browse():
  return render_template("basic_page.html")


@app.route("/term=<term_id>")
def term(term_id = None):
  
  try: 
    term = sea.getTerm(int(term_id))
    if term:
      result = seaice.printAsHTML([term])
      return render_template("basic_page.html", title = "Term - %s" % term_id, 
                                                headline = "Term", 
                                                content = Markup(result))
  except ValueError: pass

  return render_template("basic_page.html", title = "Term not found",
                                            headline = "Term", 
                                            content = Markup("Term <strong>#%s</strong> not found!" % term_id))
    
@app.route("/search", methods = ['POST', 'GET'])
def returnQuery():

  if request.method == "POST": 
    terms = sea.searchByTerm(request.form['term_string'])
    if len(terms) == 0: 
      return render_template("search.html", term_string = request.form['term_string'])
    else:
      result = seaice.printAsHTML(terms)
      return render_template("search.html", 
        term_string = request.form['term_string'], result = Markup(result))

  else: # GET
    return render_template("search.html")

## Start HTTP server. ##

if __name__ == '__main__':
    app.debug = True
    app.run('localhost', 5000)
