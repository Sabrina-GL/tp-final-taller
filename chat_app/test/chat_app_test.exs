defmodule ChatAppTest do
  use ExUnit.Case
  # doctest ChatApp

  describe "ActivityTracker" do
    test "tracks user online status" do
      ChatApp.Accounts.register_user("tracker_test", "pass")
      ChatApp.ActivityTracker.user_online("tracker_test")
      assert ChatApp.ActivityTracker.is_online?("tracker_test")
    end

    test "user marked offline stops showing as online" do
      ChatApp.Accounts.register_user("offline_test", "pass")
      ChatApp.ActivityTracker.user_online("offline_test")
      ChatApp.ActivityTracker.user_offline("offline_test")
      refute ChatApp.ActivityTracker.is_online?("offline_test")
    end
  end
end
