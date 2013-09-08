#!/usr/bin/python

import json
import urllib2
import sys
import xml.etree.ElementTree as ET

show_id = sys.argv[1]

def parse_auth_xml():
  xml_tuple = {}
  response = urllib2.urlopen('http://tviview.abc.net.au/iview/auth/?v2')
  auth_root = ET.fromstring(response.read())
  for child in auth_root:
    if child.tag == '{http://www.abc.net.au/iView/Services/iViewHandshaker}host':
      xml_tuple['host'] = child.text
    elif child.tag == '{http://www.abc.net.au/iView/Services/iViewHandshaker}server':
      xml_tuple['server'] = child.text
    elif child.tag == '{http://www.abc.net.au/iView/Services/iViewHandshaker}token':
      xml_tuple['token'] = child.text
    elif child.tag == '{http://www.abc.net.au/iView/Services/iViewHandshaker}tokenhd':
      xml_tuple['tokenhd'] = child.text
    elif child.tag == '{http://www.abc.net.au/iView/Services/iViewHandshaker}path':
      xml_tuple['path'] = child.text
  return xml_tuple

response = urllib2.urlopen('http://tviview.abc.net.au/iview/api2/?keyword=0-z')
show_list = json.loads(response.read())

selected_show = None

for show in show_list:
  if show['a'] == show_id:
    selected_show = show
    break

if selected_show == None:
  print 'show not found'
  sys.exit()

xml_tuple = parse_auth_xml()
print xml_tuple
server_base = xml_tuple['server'][:-(len('ondemand'))]

for episode in selected_show['f']:
  print "rtmpdump --resume -r \"%s%s%s\" -t \"%s?auth=%s\" -o foo.flv -W http://www.abc.net.au/iview/images/iview.jpg" % (server_base, xml_tuple['path'], episode['n'], xml_tuple['server'], xml_tuple['tokenhd'])
