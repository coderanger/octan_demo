# Octan_Backend Cookbook

A cookbook to deploy a Tomcat-based company blog.

## Attributes

* `node['octan']['prevayler_volume']` - If set, deploy in HA mode using the
  given EBS volume ID.

## HA Mode

If run on AWS with a `prevayler_volume` set, Tomcat will be automatically run
in a limited HA mode using an EBS volume to store the blog data and as lock to
determine the active instance.
