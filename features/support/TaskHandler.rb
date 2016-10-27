class TaskHandler
  def initialize(world, answers)
    @world = world
    @answers = answers[1]
  end

  def completeTask()
    answerIndex = 1;
    @answers.each do |answer|
      answerCurrentQuestion(answer)
      nextQuestion(answerIndex)
      answerIndex += 1
    end
    @world.wait_for_none_animating()
  end
  def answerCurrentQuestion(answer)
    @world.wait_for_none_animating()
    if @world.query('textField').length > 0 
      answerTextField(answer)
    else
      answerSelect(answer)
    end
  end

  def answerSelect(answer)
      @world.scroll_to_row_with_mark(answer, {:scroll_position => :top})
      @world.wait_for_none_animating()
      @world.touch("view marked: '#{answer}'")
      @world.scroll_to_cell({:query => 'tableView', :row => 0, :section => 2, :scroll_position => :top})
      @world.wait_for_none_animating()
  end

  def answerTextField(answer)
      @world.touch("view marked:'Tap to answer'")
      @world.keyboard_enter_text(answer)
  end

  def nextQuestion(answerIndex)
      if answerIndex == @answers.length
        @world.touch("button marked:'Done'")
      else 
        @world.touch("button marked:'Next'")
      end
  end
end
