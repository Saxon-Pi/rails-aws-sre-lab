=begin
create_tasks.rb: DB の構造を定義する
→ 「tasksテーブルには何列ある？」
=end

class CreateTasks < ActiveRecord::Migration[8.1]
# 「tasksテーブルをどう作るか」を定義する Migrationファイル
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :description
      t.string :status

      t.timestamps
    end
  end
end
