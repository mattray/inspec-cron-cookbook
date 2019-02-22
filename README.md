# inspec-cron

Schedules InSpec runs via cron. This is useful when the chef-client is not daemonized but you still wish to periodically run compliance scans. This cookbook leverages the [audit cookbook's inspec recipe](https://github.com/chef-cookbooks/audit/blob/master/recipes/inspec.rb) to ensure InSpec is installed.

# Attributes from other cookbooks

If you want to specify the version of InSpec, set the following:

    node['audit']['inspec_version'] = '3.6.6'

If you are using the [chef-client](https://github.com/cookbooks/chef-client/) or [audit](https://github.com/chef-cookbooks/audit) cookbooks the following attributes will be reused if available. If not, you'll need to set them accordingly.

Location of the InSpec configuration file.

    node['inspec-cron']['conf_dir'] = node['chef_client']['conf_dir']

Automate URL and token for reporting.

    node['inspec-cron']['server_url'] = node['chef_client']['config']['data_collector.server_url']
    node['inspec-cron']['token'] = node['chef_client']['config']['data_collector.token']
    node['inspec-cron']['insecure'] = node['audit']['insecure']

# Recipes

## default

This includes the `inspec-json` and `profiles` recipes. They are separate in case you do not wish to generate an inspec.json file and will rely on the Chef client.rb.

## inspec-json

Writes out an `inspec.json` configuration file to the `node['inspec-cron']['conf_dir']`.

## profiles

This recipe iterates over a hash of compliance profiles and their settings to create cron jobs to `inspec exec` them. The default is to run every 12 hours, but you may provide your own cron schedule within the hash or override the defaults. If you are running multiple profiles with the same start consider setting the `node['inspec-cron']['splay']` to spread them out.

    node['inspec-cron']['cron']['minute'] = '0'
    node['inspec-cron']['cron']['hour'] = '*/12'
    node['inspec-cron']['cron']['day'] = '*'
    node['inspec-cron']['cron']['weekday'] = '*'
    node['inspec-cron']['cron']['month'] = '*'

Currently only URLs are supported as a source for the compliance profiles. If you set any cron entries in your hash any unspecified cron expressions will be set to `*`. Your hash will look something like this:

```ruby
default['inspec-cron']['profiles'] = {
  'linux-patch-baseline': {
    'url': 'https://github.com/dev-sec/linux-patch-baseline/archive/0.4.0.zip',
    'minute': '15',
    'hour': '*/6'
  },
  'ssh-baseline': {
    'url': 'https://github.com/dev-sec/ssh-baseline/archive/2.3.0.tar.gz',
    'minute': '45'
  }
}
```

Which produces cron entries like this:

## bastion

This recipe configures the node as an InSpec bastion node to scan other machines. It iterates over a hash of IP address or hostnames with settings specific to the node and a hash of the profiles and settings to use

inspec exec https://github.com/mattray/uptime-profile -t ssh://mattray@ndnd -i ~/.ssh/id_rsa
inspec exec https://github.com/mattray/uptime-profile.git -t ssh://mattray@ndnd -i ~/.ssh/id_rsa
inspec exec https://github.com/mattray/uptime-profile
/opt/chef/embedded/bin/inspec exec https://github.com/mattray/uptime-profile --reporter automate
/opt/chef/embedded/bin/inspec exec https://github.com/mattray/uptime-profile --config config.json

Report to Automate via Chef Server
# NOTE: Must have Compliance Integrated w/ Chef Server
['audit']['reporter'] = 'chef-server-automate'
['audit']['fetcher'] = 'chef-server'

{
    'reporter' : {
        'automate' : {
            'token' : '8ZzgdoqAPRWsW4XOHRiFx7Kbobk=',
        }
    }
}
            'node_name' : 'testing',

            'stdout' : 'false',
            'insecure' : false,
            'environment' : 'dev'
