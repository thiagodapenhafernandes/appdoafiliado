# Comandos disponíveis:
# mina deploy          # faz deploy da versão atual (inclui update do symlink rails)
# mina setup           # configura diretórios e arquivos iniciais no servidor
# mina update_rails_symlink # atualiza o symlink /home/appdoafiliado.com.br/rails
# mina start           # inicia o Puma
# mina stop            # para o Puma via pumactl
# mina restart         # reinicia o Puma via pumactl
# mina full_stop       # força parada completa (kill + limpeza)
# mina puma_kill       # mata todos os processos puma (perigoso)
# mina restart_nginx   # reinicia Nginx
# mina restart_stack   # reinicia Puma e Nginx com segurança
# mina status          # mostra status do Puma e porta
# mina logs            # mostra logs da aplicação
# mina puma_logs       # mostra logs do Puma
# mina system_status   # mostra status do sistema (nginx, disco, memória)

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
                                                 '.env',
                                                 'config/master.key',
                                                 'config/credentials.yml.enc')

set :shared_dirs, fetch(:shared_dirs, []).push('log', 
                                               'tmp/pids',
                                               'public/uploads')

task :remote_environment do
  invoke :'rvm:use', 'ruby-3.3.5@app.appdoafiliado'
end

task :setup do
  command %[mkdir -p "#{fetch(:shared_path)}/log"]
  command %[chmod g+rx,u+rwx "#{fetch(:shared_path)}/log"]
  
  command %[mkdir -p "#{fetch(:shared_path)}/tmp/pids"]
  command %[chmod g+rx,u+rwx "#{fetch(:shared_path)}/tmp/pids"]

  command %[mkdir -p "#{fetch(:shared_path)}/config"]
  command %[chmod g+rx,u+rwx "#{fetch(:shared_path)}/config"]

  command %[mkdir -p "#{fetch(:shared_path)}/public/uploads"]
  command %[chmod g+rx,u+rwx "#{fetch(:shared_path)}/public/uploads"]

  command %[touch "#{fetch(:shared_path)}/config/database.yml"]
  command %[touch "#{fetch(:shared_path)}/config/secrets.yml"]
  command %[touch "#{fetch(:shared_path)}/.env"]
  command  %[echo "-----> Be sure to edit shared files: database.yml, .env, and secrets.yml"]
  
  # Create the rails symlink for nginx
  command %[echo "-----> Creating Rails symlink for Nginx..."]
  command %[rm -f /home/appdoafiliado.com.br/rails]
  command %[ln -sf "#{fetch(:current_path)}" /home/appdoafiliado.com.br/rails]
  command %[echo "-----> Rails symlink created: /home/appdoafiliado.com.br/rails -> #{fetch(:current_path)}"]
end

desc "Update Rails symlink for Nginx"
task :update_rails_symlink do
  command %[echo "-----> Updating Rails symlink for Nginx..."]
  command %[rm -f /home/appdoafiliado.com.br/rails]
  command %[ln -sf "#{fetch(:current_path)}" /home/appdoafiliado.com.br/rails]
  command %[echo "-----> Rails symlink updated: /home/appdoafiliado.com.br/rails -> #{fetch(:current_path)}"]
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
    invoke :'update_rails_symlink'
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
  command "sudo systemctl restart nginx"
end

desc "Reload Stack (Puma + Nginx)"
task :restart_stack do
  invoke :'full_stop'
  sleep 2  # dá tempo de liberar a porta
  invoke :'start'
  invoke :'restart_nginx'
end

desc "Show Puma status"
task :status do
  in_path(fetch(:current_path)) do
    command %[echo "===> Puma Status:"]
    command %[ps aux | grep puma | grep -v grep || echo "Puma não está rodando"]
    command %[echo "===> Porta 9292:"]
    command %[ss -tlnp | grep :9292 || lsof -i :9292 || echo "Porta 9292 não está em uso"]
    command %[echo "===> Arquivos PID/State:"]
    command %[ls -la #{fetch(:puma_pid)} #{fetch(:puma_state)} 2>/dev/null || echo "Arquivos PID/State não encontrados"]
  end
end

desc "Show application logs"
task :logs do
  in_path(fetch(:current_path)) do
    command %[echo "===> Últimas 50 linhas do log de produção:"]
    command %[tail -50 log/production.log 2>/dev/null || echo "Log de produção não encontrado, criando..."]
    command %[touch log/production.log && echo "Log criado, executando alguma ação para gerar logs..."]
  end
end

desc "Show Puma logs"
task :puma_logs do
  in_path(fetch(:current_path)) do
    command %[echo "===> Puma logs:"]
    command %[tail -50 log/puma_access.log 2>/dev/null || echo "Puma access log não encontrado"]
    command %[tail -50 log/puma_error.log 2>/dev/null || echo "Puma error log não encontrado"]
  end
end

desc "Show system status"
task :system_status do
  command %[echo "===> Nginx Status:"]
  command %[sudo systemctl status nginx --no-pager -l]
  command %[echo "===> Disk Usage:"]
  command %[df -h #{fetch(:deploy_to)}]
  command %[echo "===> Memory Usage:"]
  command %[free -h]
end

