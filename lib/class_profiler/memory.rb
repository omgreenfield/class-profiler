module ClassProfiler
  module Memory
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    module InstanceMethods
    end

    module ClassMethods
    end
  end
end
