# Build Notifier
[![Build Status](https://secure.travis-ci.org/jcmuller/build_status_server.png?branch=master)](http://travis-ci.org/jcmuller/build_status_server)
[![Dependency Status](https://gemnasium.com/jcmuller/build_status_server.png "Dependency Status")](https://gemnasium.com/jcmuller/build_status_server)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/jcmuller/build_status_server)

This utility is part of an XFD (eXtreme Feedback Device) solution designed and
built for my employer [ChallengePost](http://challengepost.com). It works in
conjunction with our [Jenkins](http://jenkins-ci.org) Continuous Integration
server (and its
[Notification Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Notification+Plugin))
and an [Arduino](http://arduino.cc) powered
[Traffic Light controller](https://github.com/jcmuller/TrafficLightController)
with a
pseudo-[REST](http://en.wikipedia.org/wiki/Representational_state_transfer)ful
API.

To run, you need to create a `config.yml` file. The first time you run the
application without any arguments, you will get a sample.

# Installation

    $ gem install build_status_server

# Execution

See the options you can pass in by:

    $ build_status_server -h

# Configuration file
## UDP Server
This section defines what interface and port should the UDP server listen at.
The Jenkins' Notification Plugin should be set to this parameters as well.

## TCP Client
This section is where we tell the server how to communicate with the web
enabled XFD. In the example case, there is a web server running somewhere
listening on port 4567 that responds to `/green` and `/red`.

On our installation, this represents the Traffic Light's Arduino web server.

## Store
Where the persistent state will be stored.

## Mask (optional)
You can decide to either include or ignore certain builds whose names match a
given [Regular Expression](http://en.wikipedia.org/wiki/Regular_expression).

## Verbose
Whether to display informative output messages.

# Development

`bin/test_tcp_server` is provided for development purposes only. It behaves
like the server on the
[Traffic Light controller](https://github.com/jcmuller/TrafficLightController)
project.

# Finished product
![my image](http://i.imgur.com/aK5rs.jpg)

# Wiring the traffic light
![my image](http://i.imgur.com/gUpWe.jpg)
