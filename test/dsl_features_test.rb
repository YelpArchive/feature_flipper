require 'test_helper'

class DslFeaturesTest < Minitest::Test
  def setup
    FeatureFlipper::Config.path_to_file = 'fixtures/features_dsl.rb'
    FeatureFlipper::Config.reload_config
  end

  def test_should_show_enabled_features
    assert show_feature?(:live_feature)
  end

  def test_should_not_show_disabled_features
    assert !show_feature?(:disabled_feature)
  end

  def test_should_not_show_a_feature_when_on_a_higher_environment
    Rails.stub(:env, 'production') do
      assert !show_feature?(:dev_feature)
    end
  end

  def test_should_be_able_to_get_all_features
    FeatureFlipper::Config.ensure_config_is_loaded
    all_features = FeatureFlipper::Config.features

    refute_nil all_features
    assert all_features.is_a?(Hash)
    assert_equal :dev, all_features[:dev_feature][:state]
    assert_equal 'dev feature', all_features[:dev_feature][:description]
  end

  def test_should_be_able_to_get_active_features
    Rails.stub(:env, 'production') do
      FeatureFlipper::Config.ensure_config_is_loaded
      active_features = FeatureFlipper::Config.active_features

      assert_equal 2, active_features.size
      assert_includes active_features, :live_feature
      assert_includes active_features, :enabled_beta_feature
    end
  end

  def test_show_feature_should_work_with_state_procs
    assert show_feature?(:enabled_beta_feature)
    assert !show_feature?(:disabled_beta_feature)
  end

  def test_show_feature_with_state_procs_should_not_look_at_environment
    Rails.stub(:env, 'production') do
      assert show_feature?(:enabled_beta_feature)
      assert !show_feature?(:disabled_beta_feature)
    end
  end
end
