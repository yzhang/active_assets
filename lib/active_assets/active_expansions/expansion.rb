require 'active_support'
require 'active_support/hash_with_indifferent_access'

module ActiveAssets
  module ActiveExpansions
    class Expansion
      include AssetScope
      include TypeInferrable

      attr_reader :type, :name, :assets, :namespace
      alias_method :all, :assets
      delegate :empty?, :to => :assets

      def initialize(name)
        @name = name
        @assets = []
      end

      def configure(options = {}, &blk)
        @type, @group, @namespace = options.values_at(:type, :group, :namespace)
        instance_eval(&blk) if block_given?
        self
      end

      def asset(path, options = {})
        options = HashWithIndifferentAccess.new(options)
        # map is for 1.9.2; HashWithIndifferentAccess bug?
        options.assert_valid_keys(*Asset.members.map(&:to_s))
      
        inferred_type, extension = inferred_type(path)

        options.reverse_merge!(
          :type => inferred_type || @current_type || extension || type,
          :expansion_name => name,
          :group => @current_groups
        )
        options.update(:path => path)

        members = options.values_at(*Asset.members)
        a = Asset.new(*members)

        a.valid!
        @assets << a
      end
      alias_method :a, :asset
      alias_method :_, :asset

      def group(*groups, &blk)
        @current_groups = groups
        instance_eval(&blk)
      ensure
        @current_groups = nil
      end

      def namespace(&blk)
        raise NoMethodError, "Cannot call namespace from within expansion." if block_given?
        @namespace
      end

      private
        def cleanse_path(path)
          File.join(File.dirname(path) + File.basename(path, ".#{type}"))
        end
    end
  end
end
