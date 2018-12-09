# azure_provision_tool
simple tool using azure api and bindings, stutent project

The purpose of this tool is to try azure-ruby bindings and provide some small funcionality, in this case we use a coffeegrpc fork service performing basic stuff:

```
# playing with grpc
https://github.com/softportal/coffeegrpc
```



## Requirements
* ruby
* bundler

## Installation:

```bash
    clone repo
    cd repo
    bundle install
```

## Usage

```
    Basic tool testing azure ruby bindings:
    Usage:

        - deploy:  launch the application in AzureCloud
        - remove:  delete the application
        - status:  get the status of the application
        - install: perform the remote installation
        - update:  update your remote application

    examples:
            ./azptool deploy
            ./azptool install
            ./azptool run
            ./azptool stop

```

