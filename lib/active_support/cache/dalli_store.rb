class DalliStore

  def fetch_with_tags(key, options)
    puts "Something fancy happened :: fetch"  
    fetch_without_tags(key, options)
  end

  alias_method_chain :fetch, :tags

  def write_with_tags(key, value, options)
    puts "Something fancy happened :: write"  
    write_without_tags(key, options)
  end

  alias_method_chain :write, :tags

  def delete_with_tags(key, options = nil)
    puts "Something fancy happened :: delete"  
    delete_without_tags(key, options)
  end

  alias_method_chain :delete, :tags

end