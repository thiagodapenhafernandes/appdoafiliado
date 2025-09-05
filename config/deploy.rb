# require 'mina/multistage'
require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rvm'

set :application_name, 'appdoafiliado'
set :domain, '167.99.5.194' #'appdoafiliado.com.br'
set :deploy_to, '/home/appdoafiliado.com.br/deploy'
set :repository, 'git@github.com:thiagodapenhafernandes/appdoafiliado.git'
set :branch, 'master'
set :user, 'appdoafiliado.com.br'
set :rails_env, 'production'

set :term_mode, :nil
set :keep_releases, 5

set :shared_files, fetch(:shared_files, []).push('config/database.yml',
                                                 'log', 
                                                 'tmp/pids', 
                                                 '.env',
                                                 'config/master.key',
                                                 'config/credentials.yml.enc')

set :shared_dirs, fetch(:shared_dirs, []).push('public/uploads')

task :remote_environment do
  invoke :'rvm:use', 'ruby-3.3.5@app.appdoafiliado'
end

task :setup do

  command %[mkdir -p "#{fetch(:current_path)}/log"]
  command %[chmod g+rx,u+rwx "#{fetch(:current_path)}/log"]
  command %(mkdir -p "#{fetch(:shared_path)}/pids/")

  command %[mkdir -p "#{fetch(:current_path)}/config"]
  command %[chmod g+rx,u+rwx "#{fetch(:current_path)}/config"]

  command %[touch "#{fetch(:current_path)}/config/database.yml"]
  command %[touch "#{fetch(:current_path)}/config/secrets.yml"]
  command  %[echo "-----> Be sure to edit '#{fetch(:current_path)}/config/database.yml' and 'secrets.yml'."]
end

desc "Deploys the current version to the server."
task :deploy do
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'
    # invoke :'stop'
    # invoke :'start'
    # invoke :'restart_nginx'    
  end
end

# mina restart_stack     # reinicia Puma e Nginx com segurança
# mina start             # inicia o Puma
# mina stop              # para o Puma
# mina full_stop         # kill e remove os arquivos .pid/.state
# mina restart_nginx     # reinicia Nginx

# Diretórios úteis
set :pids_path, "#{fetch(:shared_path)}/tmp/pids"
set :puma_state, "#{fetch(:pids_path)}/appdoafiliado.com.br.state"
set :puma_pid,   "#{fetch(:pids_path)}/appdoafiliado.com.br.pid"

desc "Start Puma"
task :start do
  in_path(fetch(:current_path)) do
    command %[echo "===> Starting Puma..."]
    command %[bundle exec puma -C config/puma.rb -e #{fetch(:rails_env)}]
  end
end

desc "Stop Puma"
task :stop do
  in_path(fetch(:current_path)) do
    command %[bundle exec pumactl -S #{fetch(:puma_state)} -e #{fetch(:rails_env)} stop]
  end
end

desc "Restart Puma"
task :restart do
  in_path(fetch(:current_path)) do
    command %[bundle exec pumactl -S #{fetch(:puma_state)} -e #{fetch(:rails_env)} restart]
  end
end

desc "Full Stop Puma (Kill & Clean PIDs + force kill via fuser)"
task :full_stop do
  in_path(fetch(:current_path)) do
    command %[echo "===> Parando Puma (kill PID, fuser, limpeza de state/pid)"]

    # Tenta parar via state file
    command %[if [ -f #{fetch(:puma_state)} ]; then bundle exec pumactl -S #{fetch(:puma_state)} stop || true; fi]

    # Força kill com PID se ainda existir
    command %[if [ -f #{fetch(:puma_pid)} ]; then kill -9 $(cat #{fetch(:puma_pid)}) 2>/dev/null || true; fi]

    # Mata qualquer processo usando a porta 9292 (independente de PID)
    command %[fuser -k 9292/tcp || true]

    # Limpa arquivos de pid/state
    command %[rm -f #{fetch(:puma_pid)} #{fetch(:puma_state)}]
  end
end

desc "Kill all Puma processes (unsafe)"
task :puma_kill do 
  command "kill -9 $(ps -ef | grep puma | grep -v grep | awk '{print $2}') || true"
end

desc "Restart Nginx"
task :restart_nginx do
  command "sudo service nginx restart"
end

desc "Reload Stack (Puma + Nginx)"
task :restart_stack do
  invoke :'full_stop'
  sleep 2  # dá tempo de liberar a porta
  invoke :'start'
  invoke :'restart_nginx'
end

