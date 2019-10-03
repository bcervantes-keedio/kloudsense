# KloudSense

KloudSense BigData Observability Platform


## What is it?
KloudSense is a Observability platform for monitoring, alerting, analytics and prediction of a BigData cluster's state. This provides information about the current state of cluster and it's possible errors on the future. Also, this platform can make operations in cluster's nodes based in a rules-engine which decides the correct way to fix the possible errors.


## Capabilities
KloudSense capabilities depends on the target. Now KloudSense only supports DC/OS clusters, but in the future it will can work also with Cloudera clusters:



---
### DC/OS (D2IQ)
#### Data Collected
KloudSense can collect data from DC/OS usage metrics, DC/OS components logs, and running containers logs. All these information is stored in CrateDB for the analytics. 

#### Analytics
Currently are in development some predictive models, metrics monitoring and anomalies detection for detect possible future errors and determine the cause of them.

#### Storage
The program can store as much information in its database as its storage can support. For this, CrateDB is used as the central database of the platform. This can store the information in a distributed way and keeping several copies to guarantee the availability of the collected data.

#### Visualization
KloudSense works with Grafana to create custom panels to graphically represent the state metrics of the current cluster.

#### Alerting
Alerting rules can be defined in Prometheus. When any alert fires, Prometheus can send this information to the rules engine to begin their evaluation and alert somebody with Alertmanager.

---




### Cloudera
---

*For future versions*

---




## Architecture
KloudSense is an OpenSource project, and also uses some projects Apache licensed. This projects are:

  - **Grafana**: Grafana is the Front-End module to draw Dashboards with the data stored in Prometheus.
  - **Prometheus**: Prometheus is used to ingest short-term storage of metrics (15 days by default). Also it's works as DataSource for Grafana.
  - **Alertmanager**: Sends alerts messages when a Prometheus alert fire.
  - **CrateDB-CE**: CrateDB Community Edition for long-term  storage of metrics, containers logs and system logs.
  - **CP-Adapter (Crate-Prometheus Adapter)**: Connect Prometheus with CrateDB for remote Write/Read.
  - **Drools**: Expert system based on rules to determine the cause of the alert and the properly solution. When the rules have been determined the error, Drools can trigger the execution of one or some Airflow DAGs to try to fix the error automatically.
  - **Drools-Connector**: Developed by Keedio. This module receives the alerts sent by Prometheus (like the alerts sent to Alertmanager) and send one by one these alerts to a specified container in Drools to being processed.
  - **Airflow**: Workflow Manager to execute work on monitored nodes that perform maintenance tasks.

### Architecture Diagram
**INSERT DIAGRAM HERE!**



## Component EndPoints
  - **Grafana**: http://localhost:80
  - **Prometheus**: http://localhost:60000
  - **Alertmanager**: http://localhost:60100
  - **CrateDB-CE**: http://localhost:4200
  - **Drools**: http://localhost
  - **Airflow**: http://localhost:8083


## Compatibility
|  Target  | Metrics | Logs |   Prediction   |
|:--------:|:-------:|:----:|:--------------:|
| DC/OS    | Yes     | Yes  | In Development |
| Cloudera | No      | No   | No             |


## Configuration and Deploy
Here are the instructions to configure the platform, download its modules and run it.

### Download 
```sh
# Download root repository
git clone https://github.com/kloudsense/kloudsense.git
cd kloudsense
```


### Configuration
There are some files you can edit to configure KloudSense:
  - **KloudSense properties file**: ( *./config/kloudsense.properties* ) Main config file
  - **DC/OS cluster inventory file**: ( *./dcos/bootstrap/dcos_hosts.inventory* ) Ansible inventory file
  - **Prometheus Auto-Discovery DC/OS nodes**: ( *./dcos/config/prometheus/resolv.conf* ) Linux resolv file with the nameserver of DC/OS

#### Steps
  1. Edit the Mesos DNS IP address in *./dcos/config/prometheus/resolv.conf*.
     ```sh
     sed 's/nameserver .*/nameserver <MESOS_DNS_IP>/g' dcos/config/prometheus/resolv.conf > dcos/config/prometheus/resolv.conf
     ```
  2. Create a ssh key in your monitoring host and add the public key to each DC/OS node (Master and Agents).
      ```sh
      ssh-keygen
      ssh-copy-id -i ~/.ssh/mykey user@host
      ```
  3. Edit the inventory file and configure your nodes.
      ```sh
      vim dcos/config/bootstrap/dcos_hosts.inventory
      # IMPORTANT! Fill all the sections:
      #     * cluster (all nodes)
      #     * master (master nodes)
      #     * agents (public and private agents nodes)
      #     * public_agents (public agent nodes)
      #     * private_agents (private agent nodes)
      ```


### Deploy and Run
```sh
# Run the assistant 
./kshell

# Set the configuration to DC/OS cluster 
ks mode dcos

# Run Standalone deploy
ks system up
```


### Stop Platform
```sh
# Run the assistant 
./kshell

# Stop the containers
ks system stop
```


### Start Platform
```sh
# Run the assistant 
./kshell

# Stop the containers
ks system start
```


### Help
If you have problems with the assistant commands try following the help messages
```sh
# Main Help
ks help

# Module Help
ks <MODULE> help
```



## Ownership
### Authors
 - Alejandro Villegas - LEAD Developer (<avillegas@keedio.com>)

### Owner
 - Keedio (<keedio@keedio.com>)




## License
KloudSense is distributed under [Apache 2.0 License](https://github.com/kloudsense/kloudsense/blob/master/LICENSE)
