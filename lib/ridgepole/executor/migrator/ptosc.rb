# frozen_string_literal: true

require 'ridgepole/executor/migrator/ptosc/cli'
require 'shellwords'
require 'erb'

module Ridgepole
  class Executor
    class Migrator
      # rubocop: disable Metrics/ClassLength
      # Handle the invocation of pt-osc.
      class Ptosc
        ALTER_REGEXP = /^\s*alter[\s\\]+table[\s\\]+([\\\'\"\`\w]+)/i

        attr_reader :raw_sql, :default_host, :default_user, :default_database,
                    :default_table, :default_password, :default_charset,
                    :default_recurse, :default_other_flags,
                    :default_recursion_method, :default_max_load,
                    :default_critical_load, :default_alter_foreign_keys_method,
                    :default_chunk_size, :default_sleep, :default_plugin

        def initialize
          @cli = Cli.new
          setup_default_variables
        end

        # rubocop: disable Metrics/MethodLength
        def setup_default_variables
          @default_sql = 'select 1'
          @default_host = '127.0.0.1'
          @default_charset = 'utf8mb4'
          @default_recurse = 0
          @default_recursion_method = 'none'
          @default_max_load = 'Threads_running=100'
          @default_critical_load = 'Threads_running=120'
          @default_alter_foreign_keys_method = 'rebuild_constraints'
          @default_plugin = [
            'pt-online-schema-change-fast-rebuild-constraints.pl'
          ]
          @default_chunk_size = 1000
          @default_sleep = 0.1
          @default_other_flags = []
        end
        # rubocop: enable Metrics/MethodLength

        def parse(config, metaconfig)
          @cli.parse(config, metaconfig)
        end

        def config
          @cli.config
        end

        def strip_quotes(str)
          str.sub(/^(\s*)[\'\"\`]+/, '\1').sub(/[\'\"\`]+(\s*)$/, '\1')
        end

        def parse_raw_sql_for_pt_osc
          @raw_sql =~ ALTER_REGEXP
          config['table'] = strip_quotes(Regexp.last_match(1))
          @formatted_sql = @raw_sql.gsub(ALTER_REGEXP, '').strip.shellescape
        end

        def parse_config_equivalencies_for_pt_osc
          config['user'] = config['username']
          config['plugin'] = [config['plugin'].to_s.split(/\s*,\s*/)].flatten
        end

        def run_pt_osc
          parse_raw_sql_for_pt_osc
          parse_config_equivalencies_for_pt_osc
          system(pt_osc_cmdline)
        end

        def default_formatted_sql
          @formatted_sql&.empty? ? @default_sql : @formatted_sql
        end

        def default_cmdline
          <<~ECMD
            pt-online-schema-change \\
              --alter <%= formatted_sql %> \\
              --host "<%= host %>" \\
              -u "<%= user %>" \\
              D="<%= database %>",t="<%= table %>",p="<%= password %>" \\
              --charset=<%= charset %> \\
              --recurse=<%= recurse %> \\
              --recursion-method=<%= recursion_method %> \\
              --max-load <%= max_load %> \\
              --critical-load <%= critical_load %> \\
              --alter-foreign-keys-method <%= alter_foreign_keys_method %> \\
              <%= plugin.collect {|p| "--plugin #{p}"}.join(' ') %> \\
              --chunk-size=<%= chunk_size %> \\
              --sleep=<%= sleep %> \\
              <%= other_flags&.any? && other_flags.join(' ') %>
          ECMD
        end

        def pt_osc_variables
          %w[formatted_sql host user database table password charset recurse
             recursion_method max_load critical_load alter_foreign_keys_method
             chunk_size sleep cmdline plugin other_flags]
        end

        def envname(var)
          "PTOSC_#{var.upcase}"
        end

        def env_variable(var)
          case var
          when 'plugin'
            [ENV[envname(var)].to_s.split(/\s*,\s*/)].flatten
          when 'other_flags'
            [ENV[envname(var)].to_s.split(/\s+/)].flatten
          else
            ENV[envname(var)]
          end
        end

        def pt_osc_cmdline
          b = binding
          pt_osc_variables.each do |var|
            b.local_variable_set(var,
                                 env_variable(var) ||
                                 config[var] ||
                                 __send__(:"default_#{var}"))
          end
          cmd_template = ERB.new(b.local_variable_get('cmdline'))

          cmd_template.result(b)
        end

        def alter_statement?
          config[:sql] =~ ALTER_REGEXP
        end

        def will_handle?
          alter_statement?
        end

        def do
          @raw_sql = config[:sql]
          run_pt_osc
        end
      end
      # rubocop: enable Metrics/ClassLength
    end
  end
end
