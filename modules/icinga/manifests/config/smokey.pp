class icinga::config::smokey (
  $rate_limit_token = 'UNSET',
) {
  #FIXME: This could do with a good refactor to pass these explicitly as
  #       class parameters, so they can be namespaced in hiera better.
  $smokey_vars = {
    'AUTH_USERNAME'    => hiera('http_username', 'UNSET'),
    'AUTH_PASSWORD'    => hiera('http_password', 'UNSET'),
    'EFG_DOMAIN'       => hiera('smokey_efg_domain', 'UNSET'),
    'EFG_USERNAME'     => hiera('smokey_efg_username', 'UNSET'),
    'EFG_PASSWORD'     => hiera('smokey_efg_password', 'UNSET'),
    'SIGNON_EMAIL'     => hiera('smokey_signon_email', 'UNSET'),
    'SIGNON_PASSWORD'  => hiera('smokey_signon_password', 'UNSET'),
    'BEARER_TOKEN'     => hiera('smokey_bearer_token', 'UNSET'),
    'RATE_LIMIT_TOKEN' => $rate_limit_token,
  }

  file { '/etc/smokey.sh':
    content => template('icinga/etc/smokey.sh.erb'),
    mode    => '0400',
  }

  file { '/etc/icinga/conf.d/check_smokey.cfg':
    source => 'puppet:///modules/icinga/etc/icinga/conf.d/check_smokey.cfg',
  }
}
