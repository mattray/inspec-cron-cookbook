name 'config'

default_source :supermarket

cookbook 'inspec_cron', path: '..'

run_list 'inspec_cron::inspec-json'

default['inspec_cron']['conf_dir'] = '/tmp/inspec'
default['inspec_cron']['server_url'] = 'https://ndnd/data-collector/v0/'
default['inspec_cron']['token'] = '8ZzgdoqAPRWsW4XOHRiFx7Kbobk='
default['inspec_cron']['insecure'] = true
