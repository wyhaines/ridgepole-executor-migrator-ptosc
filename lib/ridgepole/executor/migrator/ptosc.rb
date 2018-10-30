require 'ridgepole/executor/migrator/ptosc/cli'

module Ridgepole
  class Executor
    class Migrator
      class Ptosc
        def initialize
          @cli = Cli.new
        end

        def parse(config, metaconfig)
          @cli.parse(config, metaconfig)
        end

        def config
          @cli.config
        end
      end
    end
  end
end
