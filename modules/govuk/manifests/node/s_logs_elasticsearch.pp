# == Class: Govuk::Node::S_logs_elasticsearch
#
#  Node class for the logs_elasticsearch machines.
#
# === Parameters:
#
# [*rotate_hour*]
#   The hour to rotate elasticsearch indices.
#
# [*rotate_minute*]
#   The minute to rotate elasticsearch indices.
#
# [*indices_days_to_keep*]
#   The number of elasticsearch indices to keep in days.
#
# [*aws_cluster_name*]
#   The name of the tag that is used by cluster discovery in AWS
#
class govuk::node::s_logs_elasticsearch(
  $rotate_hour = 00,
  $rotate_minute = 01,
  $indices_days_to_keep = 13,
) inherits govuk::node::s_base {

  if $::aws_migration {
    $aws_cluster_name = "logs-elasticsearch-${::aws_stackname}"
  }

  $es_heap_size = floor($::memorysize_mb / 2)

  include govuk_java::openjdk7::jre

  $cluster_hostnames = [
    'logs-elasticsearch-1',
    'logs-elasticsearch-2',
    'logs-elasticsearch-3',
  ]

  class { 'govuk_elasticsearch':
    cluster_hosts          => regsubst($cluster_hostnames, '^.*$', '\0.management:9300'),
    cluster_name           => 'logging',
    heap_size              => "${es_heap_size}m",
    number_of_replicas     => '1',
    host                   => $::fqdn,
    log_index_type_count   => {
      'logs-current' => ['syslog'],
    },
    disable_gc_alerts      => true,
    open_firewall_from_all => true,
    require                => [
      Class['govuk_java::openjdk7::jre'],
      Govuk_mount['/mnt/elasticsearch']
    ],
    aws_cluster_name       => $aws_cluster_name,
  }

  elasticsearch::plugin { 'redis-river':
    module_dir => 'redis-river',
    url        => 'https://github.com/downloads/leeadkins/elasticsearch-redis-river/elasticsearch-redis-river-0.0.4.zip',
    instances  => $::fqdn,
  }

  # Install a template with some favourable settings for storing logging data.
  elasticsearch::template { 'wildcard':
    file    => 'puppet:///modules/govuk/node/s_logs_elasticsearch/wildcard-template.json',
    require => Class['govuk_elasticsearch'],
  }

  # Install a logstash-specific template which provides some tokenizers for extracting
  # source and destination application names.
  elasticsearch::template { 'logstash':
    file    => 'puppet:///modules/govuk/node/s_logs_elasticsearch/logstash-template.json',
    require => Class['govuk_elasticsearch'],
  }

  # Collect all govuk_elasticsearch::river resources exported by the environment's
  # redis machines.
  Govuk_elasticsearch::River <<| tag == 'logging' |>>

  file { '/usr/local/bin/es-rotate-passive-check':
    ensure  => present,
    mode    => '0755',
    content => template('govuk/usr/local/bin/es-rotate-passive-check.erb'),
  }

  # We only want to trigger a rotate once
  if $::hostname == $cluster_hostnames[0] {
    @@icinga::passive_check { "check_es_rotate_${::hostname}":
      service_description => 'es-rotate',
      host_name           => $::fqdn,
      freshness_threshold => 25 * (60 * 60), # 25 hours
      notes_url           => monitoring_docs_url(es-rotate),
    }

    cron { 'elasticsearch-rotate-indices':
      ensure  => present,
      user    => 'nobody',
      hour    => $rotate_hour,
      minute  => $rotate_minute,
      command => '/usr/local/bin/es-rotate-passive-check',
      require => [
        Class['govuk_elasticsearch::estools'],
        File['/usr/local/bin/es-rotate-passive-check'],
      ],
    }
  } else {
    cron { 'elasticsearch-rotate-indices':
      ensure => absent,
      user   => 'nobody',
    }
  }

  @@icinga::check::graphite { "check_elasticsearch_syslog_input_${::hostname}":
    target    => "removeBelowValue(derivative(${::fqdn_metrics}.curl_json-elasticsearch.gauge-logs-current_syslog_count),0)",
    critical  => '0.000001:',
    warning   => '0.000001:',
    desc      => 'elasticsearch not receiving syslog from logstash',
    host_name => $::fqdn,
    notes_url => monitoring_docs_url(elasticsearch-not-receiving-syslog),
  }

  Govuk_mount['/mnt/elasticsearch'] -> Class['govuk_elasticsearch']
}
