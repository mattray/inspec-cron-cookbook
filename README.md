# inspec-cron

Schedules InSpec runs via cron. This is useful when the chef-client is not daemonized but you still wish to periodically run compliance scans. This cookbook leverages [chef-ingredient](https://github.com/chef-cookbooks/chef-ingredient) if another version of InSpec is to be installed (it uses the Chef package version by default).

# Attributes from other cookbooks

If you are using the [chef-client](https://github.com/cookbooks/chef-client/) cookbook the following attributes will be reused if available. If not, you'll need to set them accordingly.

Location of the InSpec configuration file.

    node['inspec-cron']['conf_file] = node['chef_client']['conf_dir']

Automate URL and token for reporting.

    node['inspec-cron']['server_url'] = node['chef_client']['config']['data_collector.server_url']
    node['inspec-cron']['token'] = node['chef_client']['config']['data_collector.token']
    node['inspec-cron']['insecure'] = node['audit']['insecure']

# Recipes

## default

This includes the `install-inspec`, `inspec-json`, and `profiles` recipes. They are separate in case you do not wish to generate an inspec.json file.

## install-inspec

If you want to specify the version of InSpec or use a provided package, include this recipe and set either of the following:

    node['inspec-cron']['version']
    node['inspec_cron']['package_source']

Update the `node['inspec_cron']['path']` accordingly.

## inspec-json

Writes out `/etc/chef/inspec.json` configuration file, templatized with the relevant attributes. The location and filename may be overridden with `node['inspec-cron']['conf_file']`.

## profiles

This recipe iterates over a hash of compliance profiles and their settings to create cron jobs to `inspec exec` them. The default is to run every 12 hours, but you may provide your own cron schedule within the hash or override the defaults.

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

    # Chef Name: inspec_cron: HOSTNAME: linux-patch-baseline
    15 */6 * * * /opt/chef/embedded/bin/inspec exec https://github.com/dev-sec/linux-patch-baseline/archive/0.4.0.zip --json-config /etc/chef/inspec.json
    # Chef Name: inspec_cron: HOSTNAME: ssh-baseline
    45 * * * * /opt/chef/embedded/bin/inspec exec https://github.com/dev-sec/ssh-baseline/archive/2.3.0.tar.gz --json-config /etc/chef/inspec.json

## targets

This recipe configures the node to scan other machines with InSpec profiles.

### individual targets

A hash of nodes with settings specific to each and a hash of the profiles and settings to use is iterated across. Here is an example of a hash for scanning 2 nodes with profiles with their own cron settings.

```ruby
default['inspec-cron']['targets'] = {
  '10.0.0.2': {
    'profiles': {
      'uptime': {
        'url': 'https://github.com/mattray/uptime-profile',
        'minute': '*/10',
      },
    },
  },
  '10.0.0.3': {
    'environment': 'foo',
    'password': 'testing',
    'profiles': {
      'linux-patch-baseline': {
        'url': 'https://github.com/dev-sec/linux-patch-baseline/',
      },
      'uptime': {
        'url': 'https://github.com/mattray/uptime-profile',
        'minute': '*/5',
      },
    },
  }
}
```

This produces the following `crontab` entry:
```
# Chef Name: inspec-cron: 10.0.0.2: uptime
*/10 * * * * /opt/chef/embedded/bin/inspec exec https://github.com/mattray/uptime-profile --json-config /etc/chef/targets/10.0.0.2/inspec.json
# Chef Name: inspec-cron: 10.0.0.3: linux-patch-baseline
* */12 * * * /opt/chef/embedded/bin/inspec exec https://github.com/mattray/linux-patch-baseline --json-config /etc/chef/targets/10.0.0.3/inspec.json
# Chef Name: inspec-cron: 10.0.0.3: uptime
* */12 * * * /opt/chef/embedded/bin/inspec exec https://github.com/mattray/uptime-profile --json-config /etc/chef/targets/10.0.0.3/inspec.json
```

### target lists

If you have many nodes that will behave the same, you may manage them through attributes similar to this:

```ruby
default['inspec_cron']['target_list'] =   ['10.0.0.12','10.0.0.13']
default['inspec_cron']['target_settings'] = {
                                             'environment': 'legacy',
                                             'key': '/tmp/test.id_rsa',
                                             'user': 'auditor',
                                             'hour': '4'
                                            }
default['inspec_cron']['target_profiles'] = {
  'linux-patch-baseline': {
    'url': 'https://github.com/dev-sec/linux-patch-baseline/',
    'minute': '*/7',
    'hour': '*/2',
  },
  'ssh-baseline': {
    'url': 'https://github.com/dev-sec/ssh-baseline/archive/2.3.0.tar.gz'
  },
}
```

This produces the following `crontab` entry:
```
# Chef Name: inspec-cron: 10.0.0.12: linux-patch-baseline
*/7 */2 * * * /opt/chef/embedded/bin/inspec exec https://github.com/dev-sec/linux-patch-baseline/ -t ssh://auditor@10.0.0.12 --port=22 -i=/tmp/test.id_rsa --json-config /etc/chef/targets/10.0.0.12/inspec.json
# Chef Name: inspec-cron: 10.0.0.12: ssh-baseline
* 4 * * * /opt/chef/embedded/bin/inspec exec https://github.com/dev-sec/ssh-baseline/archive/2.3.0.tar.gz -t ssh://auditor@10.0.0.12 --port=22 -i=/tmp/test.id_rsa --json-config /etc/chef/targets/10.0.0.12/inspec.json
# Chef Name: inspec-cron: 10.0.0.13: linux-patch-baseline
*/7 */2 * * * /opt/chef/embedded/bin/inspec exec https://github.com/dev-sec/linux-patch-baseline/ -t ssh://auditor@10.0.0.13 --port=22 -i=/tmp/test.id_rsa --json-config /etc/chef/targets/10.0.0.13/inspec.json
# Chef Name: inspec-cron: 10.0.0.13: ssh-baseline
* 4 * * * /opt/chef/embedded/bin/inspec exec https://github.com/dev-sec/ssh-baseline/archive/2.3.0.tar.gz -t ssh://auditor@10.0.0.13 --port=22 -i=/tmp/test.id_rsa --json-config /etc/chef/targets/10.0.0.13/inspec.json
```

## Reporting to Automate via a Chef Server

If you do not want nodes directly reporting to Automate and they use a Chef Server, you can have them proxy their reports through the Chef Server. In the Chef Server `config.rb`, set the following:

    data_collector['root_url'] = 'https://your-chef-automate-server/data-collector/v0/'
    data_collector['proxy'] = true

This works without requiring authentication with the Chef Server, only the Automate token is required.

## License and Authors

- Author: Matt Ray [matt@chef.io](mailto:matt@chef.io)
- Copyright 2019, Chef Software, Inc

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
