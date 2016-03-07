
module ActionCommand
  
  # class with utilities for working with action_commands
  class Utils
    # Used for cases where you might want to pass an action a User object, or
    # the integer ID of a user object, or the unique email of a user object, and
    # have the command operate on the user object.
    # Converts an item into an object as follows:
    # 1. If item is an object of cls, then returns it
    # 2. If item is an integer, then assumes its and id and returns cls.find(item)
    # 3. Otherwise, executes the code block and passes it item.
    def self.find_object(cls, item)
      return item if item.is_a? cls
      return cls.find(item) if item.is_a? Integer
      return yield(item)
    end
  end
  
end
