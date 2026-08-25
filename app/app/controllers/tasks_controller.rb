class TasksController < ApplicationController
  def index
    @tasks = Task.all
  end

  def new
      @task = Task.new
  end

  def create
    # tasksテーブルに対応した新しい Taskオブジェクトを、Ruby のメモリ上に作る
    # -> フォームから送られてきた許可済みのデータを使って新しいTaskオブジェクトを作る
    @task = Task.new(task_params)

    if @task.save # DBへの保存処理 (INSERT)
      # DB への保存に成功したら /tasks に戻る
      redirect_to "/tasks"
    else
      # 失敗したら入力画面をもう一度表示する
      render :new, status: :unprocessable_entity
    end 
  end

  def show
    # GET /tasks/2 なら id=2 のレコードを抽出する
    @task = Task.find(params[:id])
  end

  def edit
    @task = Task.find(params[:id])
  end

  def update
    @task = Task.find(params[:id])

    if @task.update(task_params)
      redirect_to "/tasks/#{@task.id}"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # params イメージ
  #{
  #  task: {
  #    title: "コード修正",
  #    description: "Ruby on Rails",
  #    status: "進行中"
  #  }
  #}
  # params の中から task を取得して、その中の title / description / status だけを受け付ける
  def task_params
    params.require(:task).permit(:title, :description, :status)
  end
end
