require "application_system_test_case"

class TasksTest < ApplicationSystemTestCase
  # 実際にブラウザ相当の操作で /tasks にアクセスして、画面上に <h1> が存在することを確認
  test "visiting the tasks index" do
    visit tasks_url

    assert_selector "h1"
  end
end
