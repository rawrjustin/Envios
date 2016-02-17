require "thor"

module Envios
  class CLI < Thor
    desc "setup", "Setup Milieu to use a configuration file"

    method_option "path",
      aliases: ["-p"],
      default: "config/config.yml",
      desc: "Specify a configuration file path"

    def setup
      require "envios/setup"
      Setup.start
    end

    desc "read", "read in a configuration file and create xcconfig files, attach the first configuration"

    method_option "path",
      aliases: ["-p"],
      default: "config/config.yml",
      desc: "Specify a configuration file path"

    def read
      require "envios/read"
      Read.process(options[:path])
    end

    desc "set", "switch to a configuration and attach to project"

    method_option :path,
      aliases: ["-p"],
      default: "config/config.yml",
      desc: "Specify a configuration file path"

    method_option :release, :type => :boolean, :aliases => "-r", :lazy_default => false

    def set(config_name)
      require "envios/set"
      Set.process(config_name, options[:path], options[:release])
    end
  end
end
