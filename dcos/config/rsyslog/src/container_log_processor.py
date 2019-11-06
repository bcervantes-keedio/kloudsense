#!/usr/bin/env python

# Brief: Message Processor
# Author: Alejandro Villegas Lopez <avillegas@keedio.com>
################################################################################

"""A skeleton for a python rsyslog message modification plugin
   Copyright (C) 2014 by Adiscon GmbH
   This file is part of rsyslog.
   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0
         -or-
         see COPYING.ASL20 in the source distribution

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
"""

import sys
import json
import socket
import time

# skeleton config parameters
# currently none

# App logic global variables

def onInit():
    """ Do everything that is needed to initialize processing (e.g.
        open files, create handles, connect to systems...)
    """
    # most often, nothing to do here


def onReceive(msg):
    """This is the entry point where actual work needs to be done. It receives
       the messge from rsyslog and now needs to examine it, do any processing
       necessary. The to-be-modified properties (one or many) need to be pushed
       back to stdout, in JSON format, with no interim line breaks and a line
       break at the end of the JSON. If no field is to be modified, empty
       json ("{}") needs to be emitted.
       Note that no batching takes place (contrary to the output module skeleton)
       and so each message needs to be fully processed (rsyslog will wait for the
       reply before the next message is pushed to this module).
    """
    # Load JSON message Struct
    log_dict=json.loads(msg)

    # Load JSON message message
    msg_dict=json.loads(log_dict["msg"])

    # Delete "rawmsg" not necessary
    del log_dict["rawmsg"]

    # Replace ' by " for correct insert
    msg_line=str(msg_dict["line"]).replace('\'', '"')

    # Extract metadata from msg
    agent_id=msg_dict["AGENT_ID"]
    container_id=msg_dict["CONTAINER_ID"]
    executor_id=msg_dict["EXECUTOR_ID"]
    framework_id=msg_dict["FRAMEWORK_ID"]
    stream=msg_dict["STREAM"]
    syslog_identifier=msg_dict["SYSLOG_IDENTIFIER"]
    timestamp=time.time()
    syslogtag="dcos-container"
    hostname=socket.gethostname()

    # Build and return message in JSON format
    print json.dumps({ 'msg': msg_line, 'syslogtag': syslogtag, 'hostname': hostname, '$!': {'agent_id': agent_id, 'container_id': container_id, 'executor_id': executor_id, 'framework_id': framework_id, 'stream': stream, 'syslog_identifier': syslog_identifier, 'timeprocessed': timestamp}})

def onExit():
    """ Do everything that is needed to finish processing (e.g.
        close files, handles, disconnect from systems...). This is
        being called immediately before exiting.
    """
    # most often, nothing to do here


"""
-------------------------------------------------------
This is plumbing that DOES NOT need to be CHANGED
-------------------------------------------------------
Implementor's note: Python seems to very agressively
buffer stdouot. The end result was that rsyslog does not
receive the script's messages in a timely manner (sometimes
even never, probably due to races). To prevent this, we
flush stdout after we have done processing. This is especially
important once we get to the point where the plugin does
two-way conversations with rsyslog. Do NOT change this!
See also: https://github.com/rsyslog/rsyslog/issues/22
"""
onInit()
keepRunning = 1
while keepRunning == 1:
    msg = sys.stdin.readline()
    if msg:
        msg = msg[:-1] # remove LF
        onReceive(msg)
        sys.stdout.flush() # very important, Python buffers far too much!
    else: # an empty line means stdin has been closed
        keepRunning = 0
onExit()
sys.stdout.flush() # very important, Python buffers far too much!
