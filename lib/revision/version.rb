# Defines the revision ID for the revision gem
module Revision
  VERSION = "0.2.0"
end

 * (?-mix:.*<BEGIN CHANGELOG>.*)
 * 
 * Version 0.2.0 (12 Dec 2017)
 * - Now uses configuration in releasables.yaml rather than hard-coded convention
 * - Optionally commits and tags changes
 * - Traverses directory tree from subfolder
 * (?-mix:.*<END CHANGELOG>.*)