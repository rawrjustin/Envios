require 'yaml'
require 'thor/group'
require 'Xcodeproj'
require 'erubis'

module Envios
  class CLI < Thor
    class Set < Thor::Group
      # Set source root of template files
      def self.source_root
        File.expand_path("../template", __FILE__)
      end

      def self.process(config_name, file_path, release)
        # Get the settings file for the project name
        config_settings  = YAML::load( File.open( file_path ) )
        config_keys = config_settings[config_name].keys.map!(&:upcase)
        proj_file = config_settings.delete("project_name")
        using_cocoapods = config_settings.delete("using_cocoapods")

        project = Xcodeproj::Project.open "#{proj_file}"

        # Get the project root dir
        proj_root = project.path.parent

        # Get the config directory
        config_dir = Pathname.new(file_path).parent

        # If we can find a config with the matching name
        # then set all targets with this configuration
        if selected_config_path = Dir["#{proj_root}/#{config_dir}/#{config_name}.xcconfig"].first

          # Set cocoapods configuration based on release/debug
          if using_cocoapods
            xcconfig_file = File.open(selected_config_path, 'r+')
            lines = xcconfig_file.readlines
            xcconfig_file.close
            if release
              lines = ['#include "./Pods/Target Support Files/Pods/Pods.debug.xcconfig"', ''] + lines
            else
              lines = ['#include "./Pods/Target Support Files/Pods/Pods.release.xcconfig"', ''] + lines
            end
            new_xcconfig_file = File.new("selected_config_path", "w")
            lines.each { |line| new_xcconfig_file.write line }
            new_xcconfig_file.close
          end

          config_group = project.main_group["Config"]
          unless config_group
            config_group = project.main_group.new_group("Config")
          end
          config_group.set_source_tree('SOURCE_ROOT')

          puts "matching: #{selected_config_path}"
          xcfile_ref = config_group.files.find { |file| file.real_path == Pathname.new(selected_config_path) }
          unless xcfile_ref
            xcfile_ref = config_group.new_file(selected_config_path)
          end

          project.targets.each do |target|
            target.build_configurations.each do |build_config|
              build_config.base_configuration_reference = xcfile_ref
            end
          end

          # Set environment variables
          Xcodeproj::Project.schemes(proj_file).each do |scheme_name|
            scheme_path = Xcodeproj::XCScheme.shared_data_dir(proj_file) + "#{scheme_name}.xcscheme"
            scheme = Xcodeproj::XCScheme.new("#{scheme_path}")
            env_vars = scheme.launch_action.environment_variables

            config_keys.each do |key|
              env_vars["#{key}"] = "$(#{key})"
            end
            scheme.save!
          end

          # Setup the environment constants template file
          template = File.read(File.expand_path('../',__FILE__) + "/template/Environment.erb")
          template = Erubis::Eruby.new(template)
          swift_env_constants = template.result(:env_keys=>config_keys)

          env_file_path = "#{proj_root}/#{config_dir}/Environment.swift"
          File.open("#{env_file_path}", 'w') { |f| f.write(swift_env_constants) }

          file_ref = config_group.files.find { |file| file.real_path == Pathname.new(env_file_path) }
          unless file_ref
            env_file_ref = config_group.new_file(env_file_path)
          end

          # Ensure that the swift constants file is added to target
          project.targets.each do |target|
            unless target.source_build_phase.files_references.include?(env_file_ref)
              target.source_build_phase.add_file_reference(env_file_ref)
              puts "Adding Environment.swift to the \e[32m#{target.display_name}\e[0m"
            end
          end

          project.save("#{proj_root}/#{proj_file}")
          puts "You are now in your \e[35m#{config_name}\e[0m environment, use the constants in your Environment.swift file."
        end
      end
    end
  end
end
