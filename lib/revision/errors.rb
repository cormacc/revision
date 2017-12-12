module Revision
  module Errors
    class Base < StandardError; end
    class NoDefinition < Base
      def initialize(root)
        super("No definition file (#{Releasable::CONFIG_FILE_NAME}) found at root #{root}")
      end
    end
  end
end
