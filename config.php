<?php
$CONFIG = array (
  'dbtype' => 'pgsql',
  'dbname' => 'nextcloud',
  'dbhost' => 'localhost:5432',
  'dbport' => '',
  'dbuser' => 'nextcloud',
  'dbpassword' => 'replacethisdbpasswordplz',
  'memcache.local' => '\\OC\\Memcache\\Redis',
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'filelocking.enabled' => true,
  'redis' =>
  array (
    'host' => 'localhost',
    'port' => 6379,
    'timeout' => 0.0,
    'password' => '',
  ),
);
