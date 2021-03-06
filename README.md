# This package has been integrated to [genova](https://github.com/metaps/genova). ecs_deployer has finished maintenance.

# ECS Deployer

[![Gem Version](https://badge.fury.io/rb/ecs_deployer.svg)](https://badge.fury.io/rb/ecs_deployer)
[![Test Coverage](https://codeclimate.com/github/naomichi-y/ecs_deployer/badges/coverage.svg)](https://codeclimate.com/github/naomichi-y/ecs_deployer/coverage)
[![Code Climate](https://codeclimate.com/github/naomichi-y/ecs_deployer/badges/gpa.svg)](https://codeclimate.com/github/naomichi-y/ecs_deployer)
[![CircleCI](https://circleci.com/gh/naomichi-y/ecs_deployer/tree/master.svg?style=shield)](https://circleci.com/gh/naomichi-y/ecs_deployer/tree/master)

## Features

This package provides ability to deploy tasks to AWS ECS.
The library is used by [genova](https://github.com/metaps/genova).

* Task
  * Create
* Service
  * Update
* scheduled task
  * Create
  * Update

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ecs_deployer'
```

And then execute:

```ruby
$ bundle
```

Or install it yourself as:

```ruby
$ gem install ecs_deployer
```

You can specify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables for each command.
Alternatively, select AWS profile with `--profile` option.

## Task definition

Write task definition in YAML format.
For available parameters see [Task Definition Parameters](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html).

```yaml
family: nginx
container_definitions:
- name: web
  image: nginx:{{tag}}
  essential: true
  port_mappings:
  - container_port: 80
    host_port: 80
  memory: 256
```

### Encrypt of environment variables

`environment` parameter supports KMS encrypted values.
Encrypted values must be enclosed in `${XXX}`.

```yaml
- environment:
  - name: MYSQL_ROOT_PASSWORD
    value: ${...}
```

Values are decrypted when task is created.

## Usage

### Register new task

```
$ bundle exec ecs_deployer task-register --path=spec/fixtures/task.yml --replace-variables=tag:latest
Registered task: arn:aws:ecs:ap-northeast-1:xxx:task-definition/nginx:latest
```

### Encrypt environment value

```
$ bundle exec ecs_deployer encrypt --master-key=master --value='test'
Encrypted value: ${xxx}
```

### Decrypt environment value

```
$ bundle exec ecs_deployer decrypt --value='${xxx}'
Decrypted value: xxx
```

### Update service

```
$ bundle exec ecs_deployer update-service --cluster=xxx --service=xxx --wait --wait-timeout=600
Start deploying...
Deploying... [0/1] (20 seconds elapsed)
New task: arn:aws:ecs:ap-northeast-1:xxxx:task-definition/sandbox-development:68
------------------------------------------------------------------------------------------------
  arn:aws:ecs:ap-northeast-1:xxxx:task-definition/sandbox-development:67 [RUNNING]
------------------------------------------------------------------------------------------------
You can stop process with Ctrl+C. Deployment will continue.

Deploying... [1/2] (40 seconds elapsed)
New task: arn:aws:ecs:ap-northeast-1:xxxx:task-definition/sandbox-development:68
------------------------------------------------------------------------------------------------
  arn:aws:ecs:ap-northeast-1:xxxx:task-definition/sandbox-development:68 [RUNNING]
  arn:aws:ecs:ap-northeast-1:xxxx:task-definition/sandbox-development:67 [RUNNING]
------------------------------------------------------------------------------------------------
You can stop process with Ctrl+C. Deployment will continue.

Service update succeeded. [1/1]
New task definition: arn:aws:ecs:ap-northeast-1:xxxx:task-definition/sandbox-development:68
Update service: arn:aws:ecs:ap-northeast-1:xxxx:service/development
```

## SDK

### Example
```
$ cp .env.default .env
$ docker-compose build

$ docker-compose run --rm ruby bundle exec ruby example/register_task.rb
$ docker-compose run --rm ruby bundle exec ruby example/run_task.rb
$ docker-compose run --rm ruby bundle exec ruby example/update_service.rb
$ docker-compose run --rm ruby bundle exec ruby example/update_scheduled_task.rb
```

## License

MIT
