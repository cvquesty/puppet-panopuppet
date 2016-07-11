
class panopuppet (
  $wsgi_dir = '/var/www/panopuppet',
  $static_root = '/var/www/panopuppet/staticfiles',
  $secret_key = 'password123',
  $allowed_hosts = ['*'],
  $puppetdb_host = $::fqdn
){

  $puppetdb_url = "http://${puppetdb_host}:8080"

  $cfg_file = "${wsgi_dir}/config.yaml"

  package { [[
    'httpd-devel',
    'python34',
    'python34-devel',
    'libyaml-devel',
    'openldap-devel',
    'cyrus-sasl-devel',
    'gcc',
    'make',
    'panopuppet',
    'python3-mod_wsgi',
    'python34-setuptools',
    'pip',
    ]]:
  
    ensure => latest,
  }
  
  


  file { '/usr/lib64/httpd/modules/mod_wsgi.so':
    ensure  => link,
    target  => '/usr/lib64/httpd/modules/mod_wsgi3.so',
    require => [Package['httpd'], Package['mod_wsgi']],
  }

  file { $wsgi_dir :
    ensure => directory,
  } ->

  file { "${wsgi_dir}/requirements.txt":
    source => "puppet:///modules/panopuppet/requirements.txt",
  } ->

  exec { "/usr/bin/pip3 install -r ${wsgi_dir}/requirements.txt":
    creates => "${wsgi_dir}/panopuppet.db.sqlite3",
  } ->
  
  file { "${wsgi_dir}/manage.py" :
    content => template("panopuppet/manage.py.erb"),
    mode    => '0755',
  } ->
  
  file { "${wsgi_dir}/wsgi.py" :
    content => template("panopuppet/wsgi.py.erb"),
    mode    => '0755',
  } ->
  
  file { "${wsgi_dir}/config.yaml" :
    content => template("panopuppet/config.yaml.erb"),
    mode    => '0600',
  } ->
  
  exec { "/usr/bin/python3 ${wsgi_dir}/manage.py collectstatic --noinput":
    creates => "${wsgi_dir}/staticfiles/pano",
  } ->
  
  exec { "/usr/bin/python3 ${wsgi_dir}/manage.py makemigrations":
    creates => "${wsgi_dir}/panopuppet.db.sqlite3",
  } ->
  
  exec { "/usr/bin/python3 ${wsgi_dir}/manage.py syncdb --noinput":
    creates => "${wsgi_dir}/panopuppet.db.sqlite3",
  } ->
  
  exec { "/usr/bin/chown -R apache:apache ${wsgi_dir}": 
    notify => Service['httpd'],
  }
  



}


