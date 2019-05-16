module Revision
  module Errors
    class Base < StandardError; end
    class NoDefinition < Base
      def initialize(root)
        super("No definition file (#{Releasable::CONFIG_FILE_NAME}) found at root #{root}")
      end
    end
    class NotSpecified < Base
      def initialize(key)
        super("Key (#{key}) must be specifed in yaml OR passed as argument")
      end
    end
  end
end
