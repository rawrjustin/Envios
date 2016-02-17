require "thor/group"
require 'pathname'

module Envios
  class CLI < Thor
    class Setup < Thor::Group
      include Thor::Actions

      class_option "path", aliases: ["-p"], default: "config/config.yml", desc: "Specify a configuration file path"

      # Set source root of template files
      def self.source_root
        File.expand_path("../template", __FILE__)
      end

      # Creates the config in the root path if doesn't exist already
      def create
        # Check if config yaml exists already
        if selected_config_path = Dir["#{FileUtils.pwd}/#{options[:path]}"].first
          # File exists
          puts "Using existing config file at #{"#{FileUtils.pwd}/#{options[:path]}"}"
        else
          # Config file does not exist, copy over new file
          copy_file("config.yml", "#{options[:path]}")
          puts "Created example config file at #{"#{FileUtils.pwd}/#{options[:path]}"}"
        end
      end

      # Adds the config directory to .gitignore
      def ignore
        if git_root = find_git_repo

          # Find the .gitignore, create one otherwise
          gitignore_path = "#{git_root}/.gitignore"
          if !File.exists?(gitignore_path)
            create_file(gitignore_path)
          end

          config_dir_to_ignore = Pathname.new("#{options[:path]}").parent
          gitignore_file = File.open(gitignore_path)

          # If the directory already exists in gitignore, then don't
          # append to the end of existing .gitignore
          text = gitignore_file.read
          unless text =~ /#{config_dir_to_ignore}/ then
            append_to_file(gitignore_path, <<-EOF)

# Ignore Envios configuration path
#{config_dir_to_ignore}/
EOF
          end
        end
      end
    end
  end
end

# Returns the git root directory given a path inside the repo.
# Returns nil if the path is not in a git repo.
def find_git_repo(start_path = '.')
  raise NoSuchPathError unless File.exists?(start_path)

  current_path = File.expand_path(start_path)

  # for clarity: set to an explicit nil and then just return whatever
  # the current value of this variable is (nil or otherwise)
  return_path = nil

  until root_directory?(current_path)
    if File.exists?(File.join(current_path, '.git'))
      # done
      return_path = current_path
      break
    else
      # go up a directory and try again
      current_path = File.dirname(current_path)
    end
  end
  return_path
end

# Returns true if the given path represents a root directory
def root_directory?(file_path)
  File.directory?(file_path) &&
    File.expand_path(file_path) == File.expand_path(File.join(file_path, '..'))
end
