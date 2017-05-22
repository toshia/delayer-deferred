# -*- coding: utf-8 -*-

module Delayer::Deferred::Response
  class Base
    attr_reader :value
    def initialize(value)
      @value = value
    end

    def ng?
      !ok?
    end
  end

  class Ok < Base
    def ok?
      true
    end
  end

  class Ng < Base
    def ok?
      false
    end
  end
end
