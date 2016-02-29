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
targets: [target1, target2]

  default:                                 # name of the configuration
      CONSTANTS_KEY: CONSTANTS_VALUE        # key value pairs
```

4. Read configuration file and set configuration
```
envios set configuration_name
```

5. Use your generated Environment.swift variables in your swift or objc code
```
print(Environment.CONSTANTS_KEY)
NSLog([Environment constantsKey])
```
------
