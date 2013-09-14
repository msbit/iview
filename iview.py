#!/usr/bin/python

import json
import urllib2
import sys
import socket
import xml.etree.ElementTree as ET
from rtmp_protocol import RtmpClient

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
server_ip = socket.gethostbyname('cp53909.edgefcs.net')

for episode in selected_show['f']:
  cl = RtmpClient(ip = server_ip,
    port = 1935,
    tc_url = xml_tuple['server'],
    page_url = xml_tuple['path'],
    swf_url = 'http://www.abc.net.au/iview/images/iview.jpg',
    app = 'myapp')
  cl.connect([])
  cl.call(proc_name='createStream')
  cl.call(proc_name='play', parameters=['user1'])
  cl.handle_messages()
