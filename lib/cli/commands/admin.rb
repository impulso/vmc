module VMC::Cli::Command

  class Admin < Base

    def add_user(email=nil)
      email    = @options[:email] unless email
      password = @options[:password]
      email = ask("Email: ") unless no_prompt || email
      unless no_prompt || password
        password = ask("Password: ") {|q| q.echo = '*'}
        password2 = ask("Verify Password: ") {|q| q.echo = '*'}
        err "Passwords did not match, try again" if password != password2
      end
      err "Need a valid email" unless email
      err "Need a password" unless password
      display 'Creating New User: ', false
      client.add_user(email, password)
      display 'OK'.green

      # if we are not logged in for the current target, log in as the new user
      return unless VMC::Cli::Config.auth_token.nil?
      @options[:password] = password
      cmd = User.new(@options)
      cmd.login(email)
    end

    def delete_user(user_email)
      # Check to make sure all apps and services are deleted before deleting the user
      # implicit proxying

      client.proxy_for(user_email)
      @options[:proxy] = user_email
      apps = client.apps

      if (apps && !apps.empty?)
        unless no_prompt
          proceed = ask("\nDeployed applications and associated services will be DELETED, continue? [yN]: ")
          err "Aborted" if proceed.upcase != 'Y'
        end
        cmd = Apps.new(@options)
        apps.each { |app| cmd.delete_app(app[:name], true) }
      end

      services = client.services
      if (services && !services.empty?)
        cmd = Services.new(@options)
        services.each { |s| cmd.delete_service(s[:name])}
      end

      display 'Deleting User: ', false
      client.delete_user(user_email)
      display 'OK'.green
    end

  end

end