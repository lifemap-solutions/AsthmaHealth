class User
  def initialize(world, email, password)
    @world = world
    @email = email
    @password = password
  end

  def signIn()
    @world.touch("button marked:'Already Participating?'")

    @world.touch("view marked:'Email'")
    @world.keyboard_enter_text(@email)

    @world.touch("view marked:'Password'")
    @world.keyboard_enter_text(@password)

    @world.touch("button marked:'Done'")

    @world.wait_for_elements_exist( ["button marked:'Got It'"], :timeout => 10)
    @world.wait_for_none_animating()
    @world.touch("button marked:'Got It'")

    @world.wait_for_elements_exist( ["button marked:'Next'"], :timeout => 5)
    @world.touch("button marked:'Next'")

    @world.wait_for_keyboard()
    @world.keyboard_enter_text('1111')
    @world.keyboard_enter_text('1111')

    @world.wait_for_elements_exist( ["button marked:'Done'"], :timeout => 3)
    @world.touch("button marked:'Done'")

    @world.wait_for_elements_exist(["label {text ENDSWITH 'Begin'}"], :timeout => 6)
    @world.touch("label {text ENDSWITH 'Begin'}")

    @world.wait_for_elements_exist( ["view marked:'Activities'"], :timeout => 5)
    @world.wait_for_none_animating()
  end
end
