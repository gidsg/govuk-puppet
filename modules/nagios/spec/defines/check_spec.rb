require_relative '../../../../spec_helper'

# nagios::check should create file in correct place using host_name param
describe 'nagios::check', :type => :define do
  let(:title) { 'heartbeat' }
  let(:pre_condition) {  'nagios::host{"bruce-forsyth":}' }
  let(:params) {{
    "check_command" => "nice-to-see-you",
    "host_name" => "bruce-forsyth",
    "service_description" => "to see you nice"
  }}
  it { should contain_file('/etc/nagios3/conf.d/nagios_host_bruce-forsyth/heartbeat.cfg') }
end

describe 'nagios::check', :type => :define do
  let(:title) { 'default_service' }
  let(:pre_condition) {  'nagios::host{"bruce-forsyth":}' }
  let(:params) {{
    "check_command" => "nice-to-see-you",
    "host_name" => "bruce-forsyth",
    "service_description" => "has default service as regular"
  }}
  it { should contain_file('/etc/nagios3/conf.d/nagios_host_bruce-forsyth/default_service.cfg').
       with_content(/use\s+govuk_regular_service/)
     }
end

