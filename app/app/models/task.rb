=begin
task.rb: Task というデータの扱い方を定義する
→ 「どう検索・保存できる？」
→ 「どんな入力ルールがある？」
→ 「Task固有の処理は何？」
=end

class Task < ApplicationRecord
# Rails側で tasksテーブルを操作するための Model
# -> CreateTasksのMigrationで作った tasks テーブルを、Task Modelを通して操作する
    # 入力が空なら保存失敗
    validates :title, presence: true
    validates :status, presence: true
end
