class Object #module Kernel

  unless method_defined?(:instance_exec) # 1.9

    require 'thread'

    module InstanceExecMethods #:nodoc:
    end

    include InstanceExecMethods

    # Evaluate the block with the given arguments within the context of
    # this object, so self is set to the method receiver.
    #
    # From Mauricio's http://eigenclass.org/hiki/bounded+space+instance_exec
    #
    # This version has been borrowed from Rails for compatibility sake.
    #
    # NOTE: This is not a common core extension (due to the use of thread.rb)
    # and is not loaded automatically when using <code>require 'facets'</code>.
    # However it is a core method in Ruby 1.9, so this only matters for users
    # of Ruby 1.8.x or below.

    def instance_exec(*args, &block)
      begin
        old_critical, Thread.critical = Thread.critical, true
        n = 0
        n += 1 while respond_to?(method_name = "__instance_exec#{n}")
        InstanceExecMethods.module_eval { define_method(method_name, &block) }
      ensure
        Thread.critical = old_critical
      end

      begin
        __send__(method_name, *args)
      ensure
        InstanceExecMethods.module_eval { remove_method(method_name) } rescue nil
      end
    end

  end

end
