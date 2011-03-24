module NavigationHelpers
  def path_to(page_name)
    "http://test.yoursitehere.com" +
    case page_name

    when /a page/
      '/'

    when /home page/
      '/'

    when /path "(.+)"/
      $1

    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
