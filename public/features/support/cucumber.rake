begin
  require 'cucumber/rake/task'

  namespace :cucumber do

    task :ok do
      %x{cucumber --format progress --strict --tags ~@wip features}
    end

    task :wip do
      %x{cucumber --format progress --strict --tags @wip:3 --wip features}
    end

    task :no_js do
      %x{cucumber --format progress --strict --tags @javascript features}
    end

    task :js do
      %x{cucumber --format progress --strict --tags @javascript features}
    end

    task :setup_js_with_xvfb do
      puts "Cucumber test with Xvfb and firefox"
      ENV['DISPLAY'] = ":99"
      %x{Xvfb :99 -ac -screen 0 1024x768x16 2>/dev/null >/dev/null &}
      %x{firefox --display=:99 2>/dev/null >/dev/null &}
    end


    task :setup_js_with_vnc4server do
      puts "Cucumber test with vnc4server"
      ENV['DISPLAY'] = ":99"
      %x{vncserver :99 2>/dev/null >/dev/null &}
      %x{DISPLAY=:99 firefox 2>/dev/null >/dev/null &}
    end

    task :kill_js do
      puts "Killing vnc, xvfb, and ff processes"
      %x{killall Xvfb}
      %x{killall firefox}
    end

    desc 'Run all features'
    task :all => [:ok, :wip]
  end
  
  desc 'Alias for cucumber:ok'
  task :cucumber => ['cucumber:setup_js_with_xvfb', 'cucumber:ok', 'cucumber:kill_js']

  task :default => :cucumber

rescue LoadError
  desc 'cucumber rake task not available (cucumber not installed)'
  task :cucumber do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end
