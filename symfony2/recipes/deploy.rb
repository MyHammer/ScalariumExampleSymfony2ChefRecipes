node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'php'
    Chef::Log.debug("Skipping deploy::symfony2 for application #{application} as it is not an PHP app")
    next
  end
  if not File.exists?("#{deploy[:current_path]}/deps") && File.exists?("#{deploy[:current_path]}/deps.lock")
    Chef::Log.debug("Skipping deploy::symfony2 for application #{application} as it is not a Symfony2 app")
    next
  end
  
  execute "php bin/vendors update" do
    user "deploy"
    cwd deploy[:current_path]
    command "php bin/vendors update"
    action :run
  end
  
  execute "clearing the symfony app cache" do
    user "deploy"
    cwd deploy[:current_path]
    command "php app/console cache:clear --env=scalarium"
    action :run
  end
  
  execute "execute db migrations" do
    user "deploy"
    cwd deploy[:current_path]
    command "php app/console doctrine:migrations:migrate --no-interaction --env=scalarium"
    action :run
  end
  
  execute "installing assets" do
    user "deploy"
    cwd deploy[:current_path]
    command "php app/console assets:install web --env=scalarium"
    action :run
  end
  
  execute "chown app cache and log dirs to deploy:www-data" do
    user "root"
    cwd deploy[:current_path]
    command "mkdir -p app/cache; chown -R deploy:www-data app/cache; chown -R deploy:www-data app/logs; find app/cache -type d | xargs -r chmod 0770; find app/cache -type f | xargs -r chmod 0660; find app/logs -type d | xargs -r chmod 0770; find app/logs -type f | xargs -r chmod 0660;"
    action :run
  end
  
  template "#{node[:apache][:dir]}/sites-available/#{application}.conf" do
    source "symfony2-vhost.conf.erb"
    mode 0644
    owner "root"
    group "root"
    variables(
      :appname => application,
      :appdir => deploy[:current_path]
    )
  end
  
  apache_site "#{application}.conf"
  apache_site "default" do
    enable false
  end
  
end

