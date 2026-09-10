require "test_helper"

class TaskTest < ActiveSupport::TestCase
  # title なしで Task.new()
  #         ↓
  # task.valid? を実行
  # → task.rb の Task モデルに定義された Validation (validates) をチェックする
  #         ↓
  # title 必須の Validation に引っかかる
  #         ↓
  # task.valid? == false
  #         ↓
  # assert_not false
  #         ↓
  # テスト成功！
  test "titleがないTaskは無効になる" do
    task = Task.new(
      description: "Ruby on Rails",
      status: "進行中"
    )

    puts task.valid? # task オブジェクトの valid? メソッドを呼ぶ
    puts task.errors[:title]
    puts task.errors[:status]

    assert_not task.valid? # この Task が有効ではないことを確認する (false が期待値)
  end
end
