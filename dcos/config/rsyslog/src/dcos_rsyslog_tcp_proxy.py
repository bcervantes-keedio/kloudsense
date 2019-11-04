#!/usr/bin/env python3.6

# Brief: Logs Proxy between DC/OS and Rsyslog
# Author: Alejandro Villegas Lopez <avillegas@keedio.com>
################################################################################

# Libraries
import json
import socket
import time
import threading
import argparse
import logging
import errno
import os
from systemd.journal import JournaldLogHandler


# MAX Connections from DC/OS Journal
MAX_CONNECTIONS=10
logger=None




def send (rsyslog_socket, data):
    """ Send data to rsyslog socket """
    logger.debug("Sending data:  %s", data)
    print("\nSend Data: " + data)
    rsyslog_socket.send((data + "\n").encode("utf-8"))




def get_first_json(str_err, data):
    """ Return the first JSON struct in data buffer """
    # Index of Error string with the index of the next JSON struct 
    extra_data_msg_index = str_err.find("char", 0, len(str_err)) + 5
    next_msg_index = str_err[extra_data_msg_index:-1]
    
    # Extract the first JSON struct
    return data[0:int(next_msg_index)]


def process_data (rsyslog_socket, data):
    """ Process the data buffer readed from TCP socket """
    # No data recived
    if len(data) == 0:
        return ""

    # Process Data Buffer
    while 1:
        try:
            # LookUp a JSON struct
            json.loads(data)
        except json.decoder.JSONDecodeError as e:
            # Error String
            str_err = str(e)
            if str_err.startswith("Extra data:"):
                json_msg = get_first_json (str_err, data)
                data = data[len(json_msg):]
    
                # Send Data
                send(rsyslog_socket, json_msg)
    
                logger.debug("Buffered Data: %d", len(json_msg))

            elif str_err.startswith("Unterminated string starting at:"):
                break
            else:
                logger.error(str_err)
                break
        except:
            logger.error(sys.exc_info()[0])
        else:
            # Send Data
            send(rsyslog_socket, data)
            # Clean Data buffer
            data=""
            break
    return data


def worker (conn, addr, rsyslog_socket, buffer_read_size):
    """ Read from the TCP buffer and lookup for one valid JSON struct. When a 
        JSON struct is find, it sends to Rsyslog and start over
    """
    data=""
    # Read from socket forever
    while 1:
        data = data + conn.recv(buffer_read_size).decode("utf-8")

        # Connection Closed
        if not data: 
            logger.debug("Connection Closed")
            break
        else:
            data = process_data(rsyslog_socket, data)

    conn.close()


def run (dcos_ip, dcos_port, rsyslog_ip, rsyslog_port, buffer_read_size):
    """ Open sockets and create threads for process the messages of each connection """

    # Output Socket to "rsyslog"
    logger.info("Connecting to Rsyslog: %s:%d", rsyslog_ip, rsyslog_port)
    rsyslog_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        rsyslog_socket.connect((rsyslog_ip, rsyslog_port))
    except socket.error as err:
        if err.errno == errno.ECONNREFUSED:
            logger.error("Can't connect to Rsyslog")
    else:
        logger.info("Connected to Rsyslog!")

    # Input Socket from "mesos-journal"
    logger.info("Binding to %s:%d to recive DC/OS Journal logs", dcos_ip, dcos_port)
    dcos_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    dcos_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        dcos_socket.bind((dcos_ip, dcos_port))
    except socket.error as err:
        logger.error("Can't Bind to %s:%d", dcos_ip, dcos_port)
        return
    else:
        dcos_socket.listen(MAX_CONNECTIONS)
        logger.info("Accepting connections")

    while 1:
        conn, addr = dcos_socket.accept()
        thread = threading.Thread(target=worker, args=(conn, addr, rsyslog_socket, buffer_read_size), daemon=True)
        thread.start()
        logger.debug("New Connection from %s", addr)




if __name__ == "__main__":
    """ Parse Arguments, configure logging and run the app """

    # Arguments parsing
    parser = argparse.ArgumentParser(description='DC/OS Container Logs - Rsyslog Proxy')
    parser.add_argument('--dcos-journal-ip', default="127.0.0.1", help='DC/OS Journal for container logs IP')
    parser.add_argument('--dcos-journal-port', default=61092, help='DC/OS Journal for container logs Port')
    parser.add_argument('--rsyslog-ip', default="127.0.0.1", help='System Rsyslog IP')
    parser.add_argument('--rsyslog-port', default=61093, help='System Rsyslog Port')
    parser.add_argument('--buffer-read-size', default=1024, help='TCP Buffer read size')
    parser.add_argument('-v', '--verbose', default=False, action='store_true', help='Verbose mode')
    parser.add_argument('-q', '--quiet', default=False, action='store_true', help='Quiet mode')
    args = parser.parse_args()


    # Daemonize 
    # Close stdin
    os.close(0)
    # Close stdout
    os.close(1)
    # Close stderr
    os.close(2)

    # Logger configuration
    log_level=0
    if args.verbose:
        log_level=logging.DEBUG
    elif args.quiet:
        log_level=logging.ERROR
    else:
        log_level=logging.INFO

    logger = logging.getLogger(__name__)
    journald_handler = JournaldLogHandler()
    journald_handler.setFormatter(logging.Formatter("[%(levelname)s](%(asctime)s): %(message)s"))
    logger.addHandler(journald_handler)
    logger.setLevel(log_level)

    logger.debug("##-> DC/OS Journal IP: %s", args.dcos_journal_ip)
    logger.debug("##-> DC/OS Journal Port: %d", args.dcos_journal_port)
    logger.debug("##-> Rsyslog IP: %s", args.rsyslog_ip)
    logger.debug("##-> Rsyslog Port: %d", args.rsyslog_port)


    # Run Daemon
    run(args.dcos_journal_ip, args.dcos_journal_port, args.rsyslog_ip, args.rsyslog_port, args.buffer_read_size) 
