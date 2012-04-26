# Build Notifier

This utility is part of an XFD (eXtreeme Feedback Device) solution designed and
built for my employer [ChallengePost](http://challengepost.com). It works in
conjunction with our [Jenkins](http://jenkins-ci.org) Continuous Integration
server (and its
[Notification Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Notification+Plugin))
and an [Arduino](http://arduino.cc) powered
[Traffic Light controller](https://github.com/jcmuller/TrafficLightController)
with a
pseudo-[REST](http://en.wikipedia.org/wiki/Representational_state_transfer)ful
API.

To run, you need to copy `config/config-example.yml` into `config/config.yml`
and mofify accordingly.

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

# Finished product
![my image](http://i.imgur.com/aK5rs.jpg)

# Wiring the traffic light
![my image](http://i.imgur.com/gUpWe.jpg)
