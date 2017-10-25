require 'aws-sdk'
require 'yaml'
require 'oj'

module EcsDeployer
  module Task
    class Client
      def initialize(cluster, aws_options = {})
        @cluster = cluster
        @ecs = Aws::ECS::Client.new(aws_options)
        @cipher = EcsDeployer::Util::Cipher.new(aws_options)
      end

      # @param [String] path
      # @param [Hash] replace_variables
      # @return [Aws::ECS::Types::TaskDefinition]
      def register(path, replace_variables = {})
        raise IOError, "File does not exist. [#{path}]" unless File.exist?(path)

        register_hash(YAML.load(File.read(path)), replace_variables)
      end

      # @param [Hash] task_definition
      # @param [Hash] replace_variables
      # @return [Aws::ECS::Types::TaskDefinition]
      def register_hash(task_definition, replace_variables = {})
        task_definition = Oj.load(Oj.dump(task_definition), symbol_keys: true)

        replace_parameter_variables!(task_definition, replace_variables)
        decrypt_environment_variables!(task_definition)

        result = @ecs.register_task_definition(
          container_definitions: task_definition[:container_definitions],
          family: task_definition[:family],
          task_role_arn: task_definition[:task_role_arn],
          volumes: task_definition[:volumes]
        )

        result[:task_definition]
      end

      # @param [String] service
      # @return [String]
      def register_clone(service)
        result = @ecs.describe_services(
          cluster: @cluster,
          services: [service]
        )

        result[:services].each do |svc|
          next unless svc[:service_name] == service

          result = @ecs.describe_task_definition(
            task_definition: svc[:task_definition]
          )

          return register_hash(result[:task_definition].to_hash)
        end

        raise ServiceNotFoundError, "'#{service}' service is not found."
      end

      private

      # @param [Array, Hash] variables
      # @param [Hash] replace_variables
      def replace_parameter_variables!(variables, replace_variables = {})
        for variable in variables do
          if variable.class == Array || variable.class == Hash
            replace_parameter_variables!(variable, replace_variables)
          elsif variable.class == String
            replace_variables.each do |replace_key, replace_value|
              variable.gsub!("{{#{replace_key}}}", replace_value)
            end
          end
        end
      end

      # @param [Hash] task_definition
      def decrypt_environment_variables!(task_definition)
        raise TaskDefinitionValidateError, '\'container_definition\' is undefined.' unless task_definition.key?(:container_definitions)
        task_definition[:container_definitions].each do |container_definition|
          next unless container_definition.key?(:environment)

          container_definition[:environment].each do |environment|
            if environment[:value].class == String
              match = environment[:value].match(EcsDeployer::Util::Cipher::ENCRYPT_VARIABLE_PATTERN)
              environment[:value] = @cipher.decrypt(match[0]) if match
            else
              # https://github.com/naomichi-y/ecs_deployer/issues/6
              environment[:value] = environment[:value].to_s
            end
          end
        end
      end
    end
  end
end
