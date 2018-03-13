# SDR Ingest Workflow Robots

[![Build Status](https://travis-ci.org/sul-dlss/sdr-preservation-core.png?branch=master)](https://travis-ci.org/sul-dlss/sdr-preservation-core) [![Coverage Status](https://coveralls.io/repos/sul-dlss/sdr-preservation-core/badge.png?branch=master)](https://coveralls.io/r/sul-dlss/sdr-preservation-core) [![Dependency Status](https://gemnasium.com/sul-dlss/sdr-preservation-core.svg)](https://gemnasium.com/sul-dlss/sdr-preservation-core) 

**Note** As of Q1 2018, this repository is being replaced by https://github.com/sul-dlss/preservation_robots

## Authors
* Alpana Pande
* Bess Sadler
* Richard Anderson
* Darren Weber

See the [Wiki](https://github.com/sul-dlss/robot-master/wiki) for general documentation on the robots infrastructure.


## Project Structure

- config
  - certs : authentication certificates for workflow service
  - deploy : host-level Capistrano configuration
  - environments : configuration for dev,stage,prod environments
  - workflows : workflow specific configuration - steps, dependencies. One directory per workflow.
- lib : ruby classes needed for your local robots
  - sdrIngest : all of the robots for a particular workflow. One directory per workflow
- spec
  - lib : spec for library classes
  - sdrIngest : specs for the workflow


## An overview of the workflow

* See the workflow steps in config/workflows, e.g.
  - config/workflows/sdrIngestWF/sdrIngestWF.xml

* See the dependencies and settings for each step in
  - config/workflows/sdrIngestWF/workflowDefinition.xml

* Worflows must be updated in ARGO, e.g.
  - https://argo-stage.stanford.edu/catalog/druid:bb163sd6279
  - https://argo-stage.stanford.edu/view/druid:bb163sd6279/ds/workflowDefinition

* Workflow updates require restarting the robot master
  - https://github.com/sul-dlss/robot-master


## Admin Menu

```bash
alias sdr2='cd ~/sdr-preservation-core/current/bin'
alias ingest='sdr2 ; bundle exec menu.rb sdrIngestWF; cd $OLDPWD'
alias ingest-log='log sdrIngestWF'
function log() { cd ~/sdr-preservation-core/current/log/$1/current; }
```


## Crontab

See `bin/cron_jobs.txt` or `ssh` onto a deploy system and run `crontab -e`.


## Deploying Robots to a new machine checklist

* clone the code repository to your laptop, using the master branch, and install dependencies:
    ```bash
    git clone git@github.com:sul-dlss/sdr-preservation-core.git
    cd sdr-preservation-core
    bundle install
    ```
* create or update `config/deploy/{stage}.rb` to specify the server parameters, e.g.
    ```bash
    cp config/deploy/dev.rb config/deploy/{stage}.rb
    ```
    ```ruby
    # modify the defaults, e.g.
    #ENV['SDR_HOST'] ||= 'sdr-stage1'
    #ENV['SDR_USER'] ||= 'sdr_user'
    #ENV['ROBOT_ENVIRONMENT'] = 'stage'
    # Note that the value of ROBOT_ENVIRONMENT entails the existence of two config files:
    # config/environments/${ROBOT_ENVIRONMENT}.rb
    # config/environments/robots_${ROBOT_ENVIRONMENT}.yml
    ```
  * capistrano can deploy to multiple servers simultaneously
  * the `{stage}` file name can be any name, it doesn't have to be the same as a ROBOT_ENVIRONMENT
* create or update `config/environments/<ROBOT_ENVIRONMENT>.rb`
  * see config/environments/development.rb
* create or update `config/environments/robots_<ROBOT_ENVIRONMENT>.yml`
  * This defines robot names, queue lanes they are associated with, and the number of instances of the robot
  * See the extensive comments in the example file at `config/environments/robots_development.yml`
* check and initialize the deployment directory structure on each <deploy_server>, e.g.
    ```bash
    cap {stage} deploy:check
    #cap -T # this should display all the available capistrano tasks (and subtasks)
    ```
* program puppet to manage the shared_configs for <deploy_server>
  * ensure the configs are in https://github.com/sul-dlss/shared_configs/tree/sdr-preservation-core_{stage}
    * e.g. https://github.com/sul-dlss/shared_configs/tree/sdr-preservation-core_dev
    * e.g. https://github.com/sul-dlss/shared_configs/tree/sdr-preservation-core_stage
    * e.g. https://github.com/sul-dlss/shared_configs/tree/sdr-preservation-core_prod
* deploy and restart the robots, e.g.
    ```bash
    cap {stage} deploy
    # to undo a deploy, use:
    #cap <deploy_server> deploy:rollback
    ```


## Restarting Robots

### all of the robots on a server
```bash
cap <deploy_server> deploy:restart # restarts all the robots
```

### individual robots on individual servers
```bash
ssh <deploy_server>
cd ~/sdr-preservation-core/current
export ROBOT_ENVIRONMENT={environment}
bundle exec controller status  # shows the status of the robots
bundle exec controller restart # to restart all of them
bundle exec controller restart sdr_sdrIngestWF_register-sdr # to restart just this robot
```

### safest way to restart
```bash
ssh <deploy_server>
cd ~/sdr-preservation-core/current
export ROBOT_ENVIRONMENT={environment}
bundle exec controller stop
bundle exec controller quit
bundle exec controller boot
```

### kill a specific robot
```bash
kill -QUIT $PID # graceful shutdown
kill -9 $PID # kill it now!
bundle exec controller status # the robot should be restarted
```

### some things to note
* the robot machines need to be in the same zone as DOR services for firewall reasons
* the robot machines need to access the /dor/export filesystem on DOR services
* the robot machines need to access mount points configured for Moab::Config.storage_roots


## Development

### Clone the repository and install dependencies

```bash
git clone git@github.com:sul-dlss/sdr-preservation-core.git
cd sdr-preservation-core
bundle install
```
    
### Run tests

```bash
cd sdr-preservation-core
bundle install
bundle exec rspec
```


