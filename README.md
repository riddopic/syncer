Description
===========

syncer is a tool to allow you to use rsync to sync directories from multiple sources.

Requirements
============

You need to create a ~/.syncer configuration file that lists the source and destination. For example to rsync

@repos = {
  :fedore => {
    :source => 'rsync://mirrors.kernel.org/fedora/',
    :target => '/opt/yumrepos/fedora'
  },
  :myrepo => {
    :source => 'server.example.com:/home/sharding/',
    :target => '/backup/sharding'
  }
}
