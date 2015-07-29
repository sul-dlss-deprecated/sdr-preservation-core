every 5.minutes, :roles => [:app] do
  # cannot use :output with Hash/String because we don't want append behavior
  set :output, proc { '> log/verify.log 2> log/cron.log' }
  set :environment_variable, 'ROBOT_ENVIRONMENT'
  rake 'robots:verify'
end
