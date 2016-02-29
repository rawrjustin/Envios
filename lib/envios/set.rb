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

      def self.process(setting, file_path, release)
        # Get the settings file for the project name
        config_settings  = YAML::load( File.open( file_path ) )
        proj_file = config_settings["project_name"]
        targets = config_settings["targets"]
        project = Xcodeproj::Project.open "#{proj_file}"

        # Get the project root dir
        proj_root = project.path.parent

        # Get the config directory
        config_dir = Pathname.new(file_path).parent

        # If we can find a config with the matching name
        # then set all targets with this configuration
        if config_settings.has_key?(setting)
          config_keys = config_settings[setting].keys.map!(&:upcase)

          # Create a config group for our xcconfig files
          config_group = project.main_group["Config"]
          unless config_group
            config_group = project.main_group.new_group("Config")
          end
          config_group.set_source_tree('SOURCE_ROOT')

          # Check for cocoapods existence
          project.targets.each do |target|
            if targets.include? target.name
              target.build_configurations.each do |build_config|
                config_path = nil
                # Check if cocoapods xcconfig exists
                ref = build_config.base_configuration_reference
                if ref.nil?
                  config_name = "#{setting}"
                  config_path = CLI.create_config(config_settings, setting, "#{setting}-#{$1}")
                else
                  if ref.path =~ /Pods.*\/Pods[-.](.+).xcconfig/

                    # If it's a cocoapods xcconfig, make sure to add it to the include
                    config_name = "#{setting}-#{$1}"
                    config_path = CLI.create_config(config_settings, setting, config_name)
                    xcconfig_file = File.open(config_path, 'r+')
                    lines = xcconfig_file.readlines
                    xcconfig_file.close

                    pod_xcconfig = "#include \"#{proj_root}/#{ref.path}\""

                    # Add the #include for the proper cocoapods xcconfig
                    lines = [pod_xcconfig, "\n"] + lines
                    new_xcconfig_file = File.new(config_path, "w")
                    lines.each { |line| new_xcconfig_file.write line }
                    new_xcconfig_file.close
                  elsif ref.path =~ /config\/(.+).xcconfig/
                    # this is an xcconfig we created
                    existing_config_name = "#{$1}"
                    includes = File.readlines(ref.path).select { |line| line =~ /#include/ }
                    config_path = CLI.create_config(config_settings, setting, existing_config_name.gsub(/\s/,'-'))

                    xcconfig_file = File.open(config_path, 'r+')
                    lines = xcconfig_file.readlines
                    xcconfig_file.close

                    # Add the #include for the proper cocoapods xcconfig
                    lines = includes + lines
                    new_xcconfig_file = File.new(config_path, "w")
                    lines.each { |line| new_xcconfig_file.write line }
                    new_xcconfig_file.close
                  else
                    raise "Envios doesn't recognize the xcconfig format that's already in your project target's settings"
                  end
                end

                xcfile_ref = config_group.files.find { |file| file.real_path == Pathname.new(config_path).expand_path }
                unless xcfile_ref
                  xcfile_ref = config_group.new_file(config_path)
                end

                build_config.base_configuration_reference = xcfile_ref
              end
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

          file_ref = config_group.files.find { |file| file.real_path == Pathname.new(env_file_path).expand_path }
          unless file_ref
            env_file_ref = config_group.new_file(env_file_path)
          end

          # Ensure that the swift constants file is added to target
          project.targets.each do |target|
            if targets.include? target.name
              puts target.name
              unless target.source_build_phase.files_references.include?(file_ref)
                target.source_build_phase.add_file_reference(file_ref)
                puts "Adding \e[35m#{setting}\e[0m Environment.swift to the \e[32m#{target.display_name}\e[0m"
              end
            end
          end

          project.save("#{proj_root}/#{proj_file}")
          puts "You are now in your \e[35m#{setting}\e[0m environment, use the constants in your Environment.swift file."
        end
      end
    end

    def self.create_config(config, setting, config_name)
      # Write keys to file
      if config.has_key?(setting)
        file_name = "#{config_name}.xcconfig"
        xcconfig_file = File.open("config/#{file_name}", 'w')
        config[setting].each do |key, value|
          xcconfig_file.puts("#{key.upcase} = #{value}")
        end
        xcconfig_file.close
        return xcconfig_file.path
      else
        raise "No such configuration setting named #{config_name}"
      end
    end
  end
end
