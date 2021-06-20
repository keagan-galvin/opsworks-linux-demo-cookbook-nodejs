app = search(:aws_opsworks_app).first
app_path = "/srv/#{app['shortname']}"

package "git" do
  # workaround for:
  # WARNING: The following packages cannot be authenticated!
  # liberror-perl
  # STDERR: E: There are problems and -y was used without --force-yes
  options "--force-yes" if node["platform"] == "ubuntu" && node["platform_version"] == "14.04"
end

application app_path do
  javascript "4"
  environment.update("PORT" => "80")
  environment.update(app["environment"])

  git app_path do
    repository app["app_source"]["url"]
    revision app["app_source"]["revision"]
  end

  link "#{app_path}/server.js" do
    to "#{app_path}/index.js"
  end

  npm_install do
    retries 3
    retry_delay 10
  end

  bash 'Configure .env' do
    user 'root'
    code <<-EOH
    echo $'DB_HOST=#{app["environment"]["DB_HOST"]}' >#{app_path}/.env
    echo $'DB_USERNAME=#{app["environment"]["DB_USERNAME"]}' >>#{app_path}/.env
    echo $'DB_PASS=#{app["environment"]["DB_PASS"]}' >>#{app_path}/.env
    echo $'DB=#{app["environment"]["DB"]}' >>#{app_path}/.env
    echo $'PORT=80' >>#{app_path}/.env
    echo $'TOKEN_SECRET=#{app["environment"]["TOKEN_SECRET"]}' >>#{app_path}/.env
    echo $'ADMIN_USERNAME=#{app["environment"]["ADMIN_USERNAME"]}' >>#{app_path}/.env
    echo $'ADMIN_PASSWORD=#{app["environment"]["ADMIN_PASSWORD"]}' >>#{app_path}/.env
    echo $'#{app["ssl_configuration"]["certificate"]}' >>#{app_path}/cert/cert.pem
    echo $'#{app["ssl_configuration"]["private_key"]}' >>#{app_path}/cert/key.pem
    EOH
  end
end
