# azure_provision_tool
simple tool using azure api and bindings, stutent project

The purpose of this tool is to try azure-ruby bindings and provide some small funcionality, in this case we use a coffeegrpc fork service performing basic stuff:

```
# playing with grpc
https://github.com/softportal/coffeegrpc

# scripting example
https://github.com/pilotAlpal/conf_coffee_gRPC
```



## Requirements
* ruby
* bundler

## Installation:

```bash
    $ git clone https://github.com/Semedi/azure_provision_tool.git
    $ cd azure_provision_tool
    $ bundle install
```

## Usage

### Prepare configuration file

```bash
    $ cd azure_provision_tool
    $ mkdir .config && touch .config/configuration
    $ vi .config/configuration
```

#### .config/configuration:
```
:credentials:
    :client: "XxXXXXX4600970bx6"
    :sub:    "XxXXXXXbd09330b03"
    :dir:    "XxXXXXXdf05800993"
    :secret: "XxXXXXXpR0fh60cdsadad=XXXX"



:user: 'user_admin'

:access:
    - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLjmhppZG6Ur0HAZ84QXhkQkkJWDtX6YxponsJVGorxsk7Zq604CfYUES04qoA9UBl6JqgEVzKDWxzcvVEqxeaJrNU6MsDn73tIHn2ABrT5T0KmAMch1sbCzL6lOtA6bAlCyBBIYHQEtoV4NRK+DKzVjtztjE+3h837caiMG63Q87Ditg2R2iKwsL+5SFAal98suFuUtQCvym56n8u1sWUq5PiOUMoSfTdl4mQWIKI6aL3m6xAZbUAB4ZoQj5Vm/n+x4ofEzDbSqjS/2lAXyUFi42l5/Z/diBVV5x1hfrmT4heHaPTG1ppp2oj1TwObpjGXOwzPy4jkBhVVSTC3giP lucas@lucas"

    - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIz1QIrz7ENMjJzrHCQgraj9eYlY46eECQ8BXZhg4RqKajTgmTsFtG+GnOxyqcwc0jTeQcHo0eFI9xTQIXZiPxVcgDxgrBPaZluWkoJVuc6M9cgiISlM9P8h4H2SCPUKLBysj37p4PcakMI61ZT3lvCFrP9sli3gWIIBW/wAzIU+KoZrBh74iLztPRYTNGpxiDgPfWqUsEJtlWhW0+df56dQkIsvgZIKK2Cf2tg7Py3mN4D5Ti5M/xNw09NdpAyP0p3CnL46LqJ8MEKyZ4MukHYK8pbQTN6aYOm3tCp4jcp4isWGCVqACSvC2mQyFjZq51mus8LYhzOAv/5FGsXRZf semedi@semedi-pc"

:provision:
    :install: 'https://raw.githubusercontent.com/pilotAlpal/conf_coffee_gRPC/master/install.sh'
    :stop:    'https://raw.githubusercontent.com/pilotAlpal/conf_coffee_gRPC/master/stop.sh'
    :update:  'https://raw.githubusercontent.com/pilotAlpal/conf_coffee_gRPC/master/update.sh'
    :run:     'https://raw.githubusercontent.com/pilotAlpal/conf_coffee_gRPC/master/run.sh'
```


### using the tool
```
    Basic tool testing azure ruby bindings:
    Usage:

        - deploy:  launch the application in AzureCloud
        - remove:  delete the application
        - status:  get the status of the application
        - install: perform the remote installation
        - update:  update your remote application
        ...

    examples:
            ./azptool deploy
            ./azptool install
            ./azptool run
            ./azptool stop

```

