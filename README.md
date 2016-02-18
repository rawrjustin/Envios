envios
=================

Easy global environment variables for iOS/Mac Xcode Projects, using a YAML configuration file

### Getting Started
1. Install the envios gem
```
gem install envios
```
2. Navigate to where your .xcproj file is and `setup`. This will create a configuration file at `config/config.yml` and add it to your `.gitignore`
```
envios setup
```

3. Edit the configuration file
```
project_file: ProjectName.xcodeproj
uses_cocoapods: true

  default:                                 # name of the configuration
      CONSTANTS_KEY: CONSTANTS_VALUE        # key value pairs
    ```

4. Read configuration file and set configuration
```
envios read
envios set default
```

5. Use your generated Environment.swift variables in your code
```
print(Environment.CONSTANTS_KEY)
```
------
