Capistrano::Configuration.instance.load do
  namespace :gems do

    desc "Update code, run 'rake gems:install'"
    task :install, :roles => fetch(:install_roles, :app) do
      deploy.update_code
      run_with_password("sudo #{fetch(:rake, "rake")} -f #{current_release}/Rakefile #{"RAILS_ENV=#{rails_env}" if rails_env} #{fetch(:gems, "gems")}:install", {
        :prompt => "Enter sudo pw: ",
        :pty => false
      })
    end

  end
end
