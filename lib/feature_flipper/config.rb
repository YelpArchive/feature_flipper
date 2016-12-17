module FeatureFlipper
  module Config
    @features = {}
    @states   = {}

    def self.path_to_file
      @path_to_file || File.join(Rails.root, 'config', 'features.rb')
    end

    def self.path_to_file=(path_to_file)
      @path_to_file = path_to_file
    end

    def self.ensure_config_is_loaded
      return if @config_loaded

      load path_to_file
      @config_loaded = true
    end

    def self.reload_config
      @config_loaded = false
    end

    def self.features
      @features
    end

    def self.features=(features)
      @features = features
    end

    def self.states
      @states
    end

    def self.states=(states)
      @states = states
    end

    def self.get_state(feature_name)
      feature = features[feature_name]
      feature ? feature[:state] : nil
    end

    def self.active_state?(state, feature_name, context = nil)
      active = states[state]
      if active.is_a?(Hash)
        group, required_state = if %w{ feature_group required_state }.any? { |key| active.has_key?(key.to_sym) }
          [active[:feature_group], active[:required_state]]
        else
          active.to_a.flatten
        end

        has_feature_group   = group ? FeatureFlipper.active_feature_groups.include?(group) : false
        has_required_state  = required_state ? self.active_state?(required_state, feature_name, context) : false
        proc_returns_true   = if active.has_key?(:when)
          if context
            context.instance_exec(feature_name, &active[:when])
          else
            active[:when].call(feature_name) == true
          end
        else
          false
        end

        has_feature_group || has_required_state || proc_returns_true
      else
        active == true
      end
    end

    def self.is_active?(feature_name, context = nil)
      ensure_config_is_loaded

      state = get_state(feature_name)
      if state.is_a?(Symbol)
        active_state?(state, feature_name, context)
      elsif state.is_a?(Proc)
        state.call == true
      else
        state == true
      end
    end

    def self.active_features(context = nil)
      self.features.collect { |key, value| self.is_active?(key, context) ? key : nil }.compact
    end
  end

  class Mapper
    def initialize(state)
      @state = state
    end

    def feature(name, options = {})
      FeatureFlipper::Config.features[name] = options.merge(:state => @state)
    end
  end

  class StateMapper
    def in_state(state, &block)
      Mapper.new(state).instance_eval(&block)
    end
  end

  def self.features(&block)
    StateMapper.new.instance_eval(&block)
  end

  def self.active_feature_groups
    Thread.current[:feature_system_active_feature_groups] ||= []
  end

  def self.reset_active_feature_groups
    active_feature_groups.clear
  end
end
