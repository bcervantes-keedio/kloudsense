# ![KS_Build](img/ks_icon_readme.png)

[![KS_Build](https://img.shields.io/badge/Build-passing-green?style=flat)](https://github.com/kloudsense/kloudsense/releases/tag/0.2-beta) [![KS_Version](https://img.shields.io/github/v/release/kloudsense/kloudsense?color=purple&include_prereleases&label=KS%20Version)](https://github.com/kloudsense/kloudsense/releases/tag/0.2-beta) [![KS_License](http://img.shields.io/:License-Apache%202-blue.svg?style=flat&logo=apache&logoColor=yellow)](http://www.apache.org/licenses/LICENSE-2.0.txt) [![KS_Version](https://img.shields.io/badge/Docker--CE-19.03.2-blue?style=flat&logo=docker)](https://github.com/kloudsense/kloudsense/releases/tag/0.2-beta)



KloudSense BigData Observability Platform. Developed by Keedio.





## What is it?
KloudSense is a Observability platform for monitoring, alerting, analytics and prediction of a BigData cluster's state. This provides information about the current state of cluster and it's possible errors on the future. Also, this platform can make operations in cluster's nodes based in a rules-engine which decides the correct way to fix the known errors.





## Capabilities
KloudSense capabilities depends on the target. Now KloudSense only supports DC/OS clusters monitoring, but in the future it will can work also with Cloudera clusters.



### Compatibility
|  Target  | Metrics | Logs |   Prediction   |
|:--------:|:-------:|:----:|:--------------:|
| DC/OS    | Yes     | Yes  | In Development |
| Cloudera | No      | No   | No             |



### DC/OS (D2IQ)
#### Data Collected
KloudSense can collect data from DC/OS usage metrics, DC/OS components logs, and running containers logs. All these information is stored in CrateDB for analytics. 

#### Analytics
Currently are in development some predictive models, metrics monitoring and anomalies detection for detect possible future errors and determine the cause of them.

#### Storage
The program can store as much information in its database as its storage can support. For this, CrateDB is used as the main database of the platform. This can store the information in a distributed way and keeping several copies to guarantee the availability of the collected data.

#### Visualization
KloudSense works with Grafana to create custom panels to graphically represent the state metrics of the current cluster.

#### Alerting
Alerting rules can be defined in Prometheus. When any alert fires, Prometheus can send this information to the rules engine to begin their evaluation and alert somebody with Alertmanager.



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
  - **Crate-Adapter**: **(Crate-Prometheus Adapter for us (CPA))** Connect Prometheus with CrateDB for remote Write/Read.
  - **Drools**: Expert system based on rules to determine the cause of the alert and the properly solution. When the rules have been determined the error, Drools can trigger the execution of one or some Airflow DAGs to try to fix the error automatically.
  - **Airflow**: Workflow Manager to execute work on monitored nodes that perform maintenance tasks.



KloudSense own componentes developed by Keedio:
  - **Prometheus-Drools Adapter (PDA)**: This module receives the alerts sent by Prometheus (like the alerts sent to Alertmanager) and send one by one these alerts to a specified container in Drools to being processed.
  - **Rsyslog-Config**: This configuration files and codes are used to send the DC/OS system and containers logs to CrateDB for further analytics.
  - **Docker-Compose Deploy**: Deploy in standalone and connections of this system with docker-compose
  - **Analytics**: Predictive and anomaly detection models for look up possible errors on the target cluster.
  - **Alert Rules**: Main Prometheus alerting rules for detect the more common error situations.
  - **Drools Rules**: Rules to make decisions based in the Prometheus Alerts.
  - **Airflow DAGs**: DAGs of Apache Airflow to make actions on the cluster. 

The rules, dags and config are customizable for each cluster and context.



### Architecture Diagram
![ks_architecture_main](img/ks_architecture_main.png "KloudSense Architecture Diagram")





## Component EndPoints
  - **Grafana**: http://localhost:20000
  - **Prometheus**: http://localhost:20100
  - **Alertmanager**: http://localhost:20110
  - **CrateDB-CE-lb-1-UI**: http://localhost:20200
  - **CrateDB-CE-lb-2-UI**: http://localhost:20201
  - **CrateDB-CE-lb-1-PSQL**: http://localhost:20210
  - **CrateDB-CE-lb-2-PSQL**: http://localhost:20211
  - **Airflow-Webserver**: http://localhost:20300
  - **Drools-WildFly**: http://localhost:20400
  - **Drools-WildFly-Management-Console**: http://localhost:20410 Credentials: (User: 'keedio' Password: 'keedio')
  - **Drools-Business-Central**: http://localhost:20400/business-central Credentials: (User: 'workbench' Password: 'workbench')





## Deploy Modes
  - **Standalone with Docker**: Available
  - **Apache Mesos**: *for future versions*





## Configuration and Deploy
KloudSense is composed by some modules to build all the system components. Here are the instructions to configure the platform, download its modules and run it.



### Dependencies
  - **Docker-CE**: >= v18
  - **Docker-Compose** >= 1.23.1
  - **Ansible** >= 2.8.5
  - **Kernel Config**: Run the following commands to increase the kernel max virtual memory areas (vm.max_map_count) required by CrateDB
      ```sh
      echo "vm.max_map_count = 262144" >> /etc/sysctl.conf 
      sysctl -w vm.max_map_count=262144

      ## If you only change the '/etc/sysctl.conf' itis 
      ```



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



---
### DC/OS Deploy

#### Steps
  1. Edit the Mesos DNS IP address of the DC/OS Cluster in *./dcos/config/prometheus/resolv.conf*.
     ```sh
     sed -i 's/nameserver .*/nameserver <MESOS_DNS_IP>/g' dcos/config/prometheus/resolv.conf
     ```
  2. Create a ssh key in your monitoring host and add the public key to each DC/OS node (Master and Agents).
      ```sh
      ssh-keygen
      ssh-copy-id -i ~/.ssh/mykey user@host
      ssh-keyscan -H host >> ~/.ssh/known_hosts
      ```
      If your cluster have so much nodes, you can use a loop to make the config process more easy.

        **NOTE!**: the user to login in the DC/OS hosts must have administration permises.

      To help you in this step, there is a little bash script to make this faster. The script requires that the inventory file of the step 3 was completed.
      * Script path = tools/ssh_key_installer.sh

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



#### Downlaod and build KloudSense Modules
KloudSense have a interactive shell based on bash to make more easy the configuration, management and deployment of the system. This shell is called 'kshell'. We recommend to use it with the following steps:
```sh
# Run the assistant
./kshell

# Set the configuration to DC/OS cluster
ks mode dcos

# Check the current modules status
ks module list

> [*] Module Name: ks-alertmanager:0.2-beta                            [absent] [not-pulled]
> [*] Module Name: ks-prometheus:0.2-beta                              [absent] [not-pulled]
> [*] Module Name: ks-grafana-meta:0.2-beta                            [absent] [not-pulled]
> [*] Module Name: ks-grafana-dcos:0.1-beta                            [absent] [not-pulled]
> [*] Module Name: ks-cratedb-ce:0.1.2-beta                            [absent] [not-pulled]
> [*] Module Name: ks-cp-adapter:0.1.1-beta                            [absent] [not-pulled]
> [*] Module Name: ks-airflow:0.1-beta                                 [absent] [not-pulled]
> [*] Module Name: ks-rules-engine:0.1-beta                            [absent] [not-pulled]
> [*] Module Name: ks-rules-engine-connector:0.1-beta                  [absent] [not-pulled]


# Download modules repositories
ks module pull

# Check if all the modules are pulled
ks module list

> [*] Module Name: ks-alertmanager:0.2-beta                            [absent] [pulled]
> [*] Module Name: ks-prometheus:0.2-beta                              [absent] [pulled]
> [*] Module Name: ks-grafana-meta:0.2-beta                            [absent] [pulled]
> [*] Module Name: ks-grafana-dcos:0.1-beta                            [absent] [pulled]
> [*] Module Name: ks-cratedb-ce:0.1.2-beta                            [absent] [pulled]
> [*] Module Name: ks-cp-adapter:0.1.1-beta                            [absent] [pulled]
> [*] Module Name: ks-airflow:0.1-beta                                 [absent] [pulled]
> [*] Module Name: ks-rules-engine:0.1-beta                            [absent] [pulled]
> [*] Module Name: ks-rules-engine-connector:0.1-beta                  [absent] [pulled]


# Build the modules (it can take a while, but only is necessary the first time)
ks module build

# Check if all the modules are builded
ks module list
> [*] Module Name: ks-alertmanager:0.2-beta                            [present] [pulled]
> [*] Module Name: ks-prometheus:0.2-beta                              [present] [pulled]
> [*] Module Name: ks-grafana-meta:0.2-beta                            [present] [pulled]
> [*] Module Name: ks-grafana-dcos:0.1-beta                            [present] [pulled]
> [*] Module Name: ks-cratedb-ce:0.1.2-beta                            [present] [pulled]
> [*] Module Name: ks-cp-adapter:0.1.1-beta                            [present] [pulled]
> [*] Module Name: ks-airflow:0.1-beta                                 [present] [pulled]
> [*] Module Name: ks-rules-engine:0.1-beta                            [present] [pulled]
> [*] Module Name: ks-rules-engine-connector:0.1-beta                  [present] [pulled]

# If you see the same output means that all modules are ready
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
---



### Cloudera Deploy

---

*for future versions*

---





## Ownership

### Authors
 - Alejandro Villegas - LEAD Developer (<avillegas@keedio.com>)

### Contact
 - Alejandro Villegas - (<avillegas@keedio.com>)

### Owner
 - Keedio (<keedio@keedio.com>)





## License
KloudSense is distributed under [Apache 2.0 License](https://github.com/kloudsense/kloudsense/blob/master/LICENSE)
