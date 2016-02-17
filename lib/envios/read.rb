require 'yaml'
require "thor"

module Envios
  class CLI < Thor
    class Read
      def self.process(file_path)
        config  = YAML::load( File.open( file_path ) )

        # Setup
        config.delete("using_cocoapods")
        config.delete("project_name")

        # Write keys to file
        config.each do |key, array|
          raise "Incorrect value type in config YAML, must be an array for each setting" if array.class != Hash

          file_name = "#{key}.xcconfig"
          xcconfig_file = File.open("config/#{file_name}", 'w')

          array.each do |key, value|
            xcconfig_file.puts("#{key.upcase} = #{value}")
          end

          xcconfig_file.close

          puts "Created environment: \e[36m#{key}\e[0m"
        end
      end
    end
  end
end
