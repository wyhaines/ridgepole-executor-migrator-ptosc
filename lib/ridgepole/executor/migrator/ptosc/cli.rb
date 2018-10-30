# frozen_string_literal: true

require 'optparse'
require 'swiftcore/tasks'
require 'ridgepole/executor/config'

module Ridgepole
  class Executor
    class Migrator
      class Ptosc
        # Parse command line arguments for this CLI.
        class Cli
          Task = Swiftcore::Tasks::Task
          DEFAULT_CMD = 'pt-online-schema-change'
          attr_reader :config, :metaconfig

          def initialize
            @config = Config.new
            @config[:command] = DEFAULT_CMD
            @metaconfig = Config.new
          end

          def _opt_bind(opts, call_list)
            opts.on('-b', '--bind HOST[:PORT}|PATH') do |bind|
              call_list << Task.new(9000) do
                if File.exist?(bind)
                  @config[:socket] = bind
                else
                  @config[:host], @config[:port] = bind.split(/:/, 2)
                end
              end
            end
          end

          def _opt_cmdline(opts, call_list)
            opts.on('-c', '--command COMMAND') do |command|
              call_list << Task.new(9000) { @config[:command] = command }
            end
          end

          def _opt_database(opts, call_list)
            opts.on('-d', '--database DATABASE') do |database|
              call_list << Task.new(9000) { @config[:database] = database }
            end
          end

          def _opt_password(opts, call_list)
            opts.on('-p', '--password PASSWORD') do |password|
              call_list << Task.new(9000) { @config[:password] = password }
            end
          end

          def _opt_user(opts, call_list)
            opts.on('-u', '--user USERNAME') do |user|
              call_list << Task.new(9000) { @config[:user] = user }
            end
          end

          def _setup_helptext
            @metaconfig[:helptext] << <<~EHELP
  The following flags all affect the parameters passed to pt-osc. Unless
  otherwise noted, all of these will override anything passed via the
  JSONCONFIG at the end of the command line. Several of these may also inherit
  configuration parsed from the adapter command line parsing (which will
  always occur before the migrator command line argument parsing), if they
  are not provided via the flags below. These will be noted below.

  --migrator-alter SQL:
    The ALTER statement that will be ran by pt-osc. This overrides anything
    specified without a flag at the end of the command line (in the SQL
    position indicated at the top of this help document).

  --migrator-database DBNAME:
    Specify the database to operate on.

  --migrator-host HOSTNAME:
    Specify the host that the MySQL database is running on. If not provided,
    or inherited from the adapter configuration, this defaults to '127.0.0.1'.

  --migrator-password PASSWORD:
    Specify the password to use to authenticate against the database. This will
    inherit from anything provided to the adapter configuration, but may be
    specified here if pt-osc is to use different authentication than the
    adapter does for SQL being executed directly.

  --migrator-table TABLE:
    Specify the table to operate against. This will be extracted from the
    SQL being executed if not provided. This parameter would not normally be
    overridden on the command line.

  --migrator-user USERNAME:
    Specify the username to use to authenticate against the database. This will
    inherit from anything provided to the adapter configuration, but may be
    specified here if pt-osc is to use different authentication  than the
    adapter does for SQL being executed directly.

  --migrator-alter-foreign-keys-method METHOD:
    Specify the method that pt-osc will use to handle foreign keys. If not
    provided, this defaults to 'rebuild_constraints'.

  --migrator-charset CHARSET:
    Specify the character set to use. If not provided, this defaults to
    'utf8mb4'.

  --migrator-chunk-size SIZE:
    Specify the chunk size for pt-osc operations. If not provided, this
    defaults to '1000'.

  --migrator-critical-load LOAD:
    Specify the critical load parameter for pt-osc. If not provided, this
    defaults to 'Threads_running=120'.

  --migrator-dry-run:
    Tell pt-osc to do perform a dry run on the requested ALTER.

  --migrator-execute
    Tell pt-osc to apply the changes being requested. This is the default.

  --migrator-max-load LOAD:
    Specify the max load parameter for pt-osc. If the load exceeds what is
    provided, pt-osc will pause to allow it to fall. If this is not provided,
    it will default to 'Threads_running=100'.

  --migrator-plugin PLUGINNAME:
    Specify an external plugin for pt-osc to run.

  --migrator-recurse DEPTH:
    Specify the recursion depth for pt-osc when discovering replicas. This
    works with the recursion-method, and will default to '0'.

  --migrator-recursion-method METHOD:
    Specify the recursion method to use to discover replicas. This will
    default to 'none'.

  --migrator-sleep TIME:
    Specify the amount of time to sleep between processing of chunks. A sleep
    period helps to ensure that the database does not get overwhelmed with
    word related to performing the ALTER change.
            EHELP
          end

          def _opt_alter(opts, call_list)
            opts.on('--migrator-alter') do |sql|
              call_list << Task.new(9000) { @config[:alter] = sql }
            end
          end

          def _opt_database(opts, call_list)
            opts.on('--migrator-database') do |database|
              call_list << Task.new(9000) { @config[:database] = database }
            end
          end

          def _opt_host(opts, call_list)
            opts.on('--migrator-host') do |host|
              call_list << Task.new(9000) { @config[:host] = host }
            end
          end

          def _opt_password(opts, call_list)
            opts.on('--migrator-password') do |password|
              call_list << Task.new(9000) { @config[:password] = password }
            end
          end

          def _opt_table(opts, call_list)
            opts.on('--migrator-table') do |table|
              call_list << Task.new(9000) { @config[:table] = table }
            end
          end

          def _opt_user(opts, call_list)
            opts.on('--migrator-user') do |user|
              call_list << Task.new(9000) { @config[:user] = user }
            end
          end

          def _opt_fkmethod(opts, call_list)
            opts.on('--migrator-fkmethod') do |fkmethod|
              call_list << Task.new(9000) { @config[:fkmethod] = fkmethod }
            end
          end

          def _opt_charset(opts, call_list)
            opts.on('--migrator-charset') do |charset|
              call_list << Task.new(9000) { @config[:charset] = charset }
            end
          end

          def _opt_chunk(opts, call_list)
            opts.on('--migrator-chunk') do |chunk|
              call_list << Task.new(9000) { @config[:chunk] = chunk }
            end
          end

          def _opt_critial_load(opts, call_list)
            opts.on('--migrator-critical-load') do |critical_load|
              call_list << Task.new(9000) { @config[:critical_load] = critical_load }
            end
          end

          def _opt_dry_run(opts, call_list)
            opts.on('--migrator-dry-run') do |dry_run|
              call_list << Task.new(9000) { @config[:dry_run] = dry_run }
            end
          end

          def _opt_execute(opts, call_list)
            opts.on('--migrator-execute') do |execute|
              call_list << Task.new(9000) { @config[:execute] = execute }
            end
          end

          def _opt_max_load(opts, call_list)
            opts.on('--migrator-max-load') do |max_load|
              call_list << Task.new(9000) { @config[:max_load] = max_load }
            end
          end

          def _opt_plugin(opts, call_list)
            opts.on('--migrator-plugin') do |plugin|
              call_list << Task.new(9000) { @config[:plugin] = plugin }
            end
          end

          def _opt_recurse(opts, call_list)
            opts.on('--migrator-recurse') do |recurse|
              call_list << Task.new(9000) { @config[:recurse] = recurse }
            end
          end

          def _opt_recursion_method(opts, call_list)
            opts.on('--migrator-recursion-method') do |recursion_method|
              call_list << Task.new(9000) { @config[:recursion_method] = recursion_method }
            end
          end

          def _opt_sleep(opts, call_list)
            opts.on('--migrator-sleep') do |sleep|
              call_list << Task.new(9000) { @config[:sleep] = sleep }
            end
          end

          def _handle_options(opts, call_list)
            %q{alter database host password table user fkmethod charset
               chunk_size critical_load dry_run execute max_load plugin
               recurse recursion_method sleep}.each do |m|
              __send__(:"_opt_#{m}", opts, call_list)
            end
          end

          def _handle_leftovers(options)
            leftovers = []

            begin
              options.parse!(ARGV)
            rescue OptionParser::InvalidOption => e
              e.recover ARGV
              leftovers << ARGV.shift
              leftovers << ARGV.shift if ARGV.any? && (ARGV.first[0..0] != '-')
              retry
            end

            ARGV.replace(leftovers) if leftovers.any?
          end

          def parse(config, metaconfig)
            @config.merge!(config)
            @metaconfig.merge!(metaconfig)
            call_list = Swiftcore::Tasks::TaskList.new
            _setup_helptext

            options = OptionParser.new do |opts|
              _handle_options(opts, call_list)
            end
            _handle_leftovers(options)

            call_list.run
          end
        end
      end
    end
  end
end
