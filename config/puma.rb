require 'dotenv/load'

threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
threads threads_count, threads_count

rails_env = ENV.fetch("RAILS_ENV", "development")
environment rails_env

workers(rails_env == "production" ? 3 : 0)
plugin :tmp_restart

app_dir = File.expand_path("../..", __FILE__)
tmp_dir = "#{app_dir}/tmp"

if rails_env == "production"
  bind "tcp://127.0.0.1:9292"
  daemonize true
else
  port ENV.fetch("PORT", 3000)
end

pidfile     "#{tmp_dir}/pids/appdoafiliado.com.br.pid"
state_path  "#{tmp_dir}/pids/appdoafiliado.com.br.state"
