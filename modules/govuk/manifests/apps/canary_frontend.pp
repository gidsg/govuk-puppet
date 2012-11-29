# The GOV.UK canary is a simple uncacheable item on www.gov.uk which is used
# to assert that the origin datacentre is up. It is fetched by Pingdom.

class govuk::apps::canary_frontend {

  $app_domain = extlookup('app_domain')


  # TODO: remove this and use HTTPS when the dev VM is SSL-only
  $scheme = $::govuk_platform ? {
    'development' => 'http',
    default       => 'https',
  }

  nginx::config::site { "canary-frontend.${app_domain}":
    content => "
      server {
        listen 80;
        listen 443 ssl;
        server_name canary-frontend.${app_domain};
        location / {
          proxy_pass ${scheme}://canary-backend.${app_domain};
        }
      }
    ",
  }

}
