class govuk::apps::collections(
  $port = 3070,
  $enabled = false,
  $vhost_protected
) {

  if str2bool($enabled) {
    govuk::app { 'collections':
      app_type              => 'rack',
      port                  => $port,
      vhost_protected       => $vhost_protected,
      health_check_path     => '/oil-and-gas',
      log_format_is_json    => true,
      asset_pipeline        => true,
      asset_pipeline_prefix => 'collections',
    }
  }
}
