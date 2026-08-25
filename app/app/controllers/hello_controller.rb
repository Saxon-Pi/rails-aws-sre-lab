class HelloController < ApplicationController # ApplicationController を継承した HelloController クラスを定義する
  def index
    @message = "Hello Rails!"
    @name = "Saxon"
    @technologies = ["Ruby", "Rails", "AWS", "Terraform"]
  end
end
