require_relative '../../../../spec_helper'

describe 'govuk_jenkins', :type => :class do
  let(:ssh_dir) { '/var/lib/jenkins/.ssh' }

  let(:facts) {{
    :jenkins_plugins => 'fake_plugin 1.0'
  }}

  it { is_expected.to contain_class('govuk_jenkins::config') }
  it { is_expected.to contain_class('govuk_jenkins::user') }
  it { is_expected.to contain_class('govuk_jenkins::package') }
  it { is_expected.to contain_class('govuk_jenkins::ssh_key')  }
end
