module EcsDeployer
  module ScheduledTask
    class Target
      attr_reader :id
      attr_accessor :cloudwatch_event_role_arn, :task_definition_arn, :task_count, :task_role_arn

      # @param [String] cluster
      # @param [String] id
      # @param [Hash] aws_options
      # @return EcsDeployer::ScheduledTask::Target]
      def initialize(cluster, id, aws_options = {})
        ecs = Aws::ECS::Client.new(aws_options)
        clusters = ecs.describe_clusters(clusters: [cluster]).clusters
        raise ClusterNotFoundError, "Cluster does not eixst. [#{cluster}]" if clusters.count.zero?

        @id = id
        @arn = clusters[0].cluster_arn
        @task_count = 1
        @container_overrides = []
      end

      # @param [String] name
      # @param [Array] command
      # @param [Hash] environments
      def override_container(name, command = nil, environments = {})
        override_environments = []
        environments.each do |environment|
          environment.each do |env_name, env_value|
            override_environments << {
              name: env_name,
              value: env_value
            }
          end
        end

        container_override = {
          name: name,
          command: command
        }
        container_override[:environment] = override_environments if override_environments.count.positive?

        @container_overrides << container_override
      end

      # @return [Hash]
      def to_hash
        {
          id: @id,
          arn: @arn,
          role_arn: @cloudwatch_event_role_arn,
          ecs_parameters: {
            task_definition_arn: @task_definition_arn,
            task_count: @task_count
          },
          input: {
            taskRoleArn: @task_role_arn,
            containerOverrides: @container_overrides
          }.to_json.to_s
        }
      end
    end
  end
end
