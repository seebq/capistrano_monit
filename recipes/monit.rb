# tasks for setting up monit

set :domain, "yourserver.com"
set :mongrel_port, "8000"
set :monit_daemon_interval, "120"
set :monit_alert_email, "you@example.com"

namespace :monit do
  desc "Setup monit daemon monitoring"
  task :setup do
  
    monit_configuration = <<-EOF
# This monit configuration was generated dynamically
set daemon #{monit_daemon_interval}
set logfile syslog facility log_daemon
set mailserver localhost
set alert #{monit_alert_email}

check system #{domain}
  if loadavg (1min) > 4 then alert
  if loadavg (5min) > 2 then alert
  # if memory usage > 75% then alert
  # if cpu usage (user) > 70% then alert
  # if cpu usage (system) > 30% then alert
  # if cpu usage (wait) > 20% then alert

EOF
  put monit_configuration, "#{shared_path}/main.conf"
  sudo "cp #{shared_path}/main.conf /etc/monit.d/"
  sudo "rm -f #{shared_path}/main.conf"

  monit_mongrel_configuration = <<-EOF
# This monit configuration was generated dynamically
#
EOF

    (0..mongrel_servers-1).each do |server|
      monit_mongrel_configuration +=<<-EOF
check process mongrel-#{mongrel_port + server} with pidfile /var/run/mongrel_cluster/#{application}.#{mongrel_port + server}.pid
  group mongrel
  start program = "/usr/bin/mongrel_rails cluster::start -C /etc/mongrel_cluster/#{application}.conf --only #{mongrel_port + server} --clean"
  stop program  = "/usr/bin/mongrel_rails cluster::stop -C /etc/mongrel_cluster/#{application}.conf --only #{mongrel_port + server} --force --clean"
  if totalmem > 100.0 MB for 5 cycles then restart
  # if failed port #{mongrel_port + server} protocol http with timeout 45 seconds then restart

EOF
    end

    put monit_mongrel_configuration, "#{shared_path}/#{application}.conf"
    sudo "cp #{shared_path}/#{application}.conf /etc/monit.d/"
    sudo "rm -f #{shared_path}/#{application}.conf"  
  end
  
  desc "Restart monit daemon monitoring"
  task :restart do
    sudo "/etc/init.d/monit restart"
  end
end
