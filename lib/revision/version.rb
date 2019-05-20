# Defines the revision ID for the revision gem
module Revision
  VERSION = "1.3.1"
end

# <BEGIN CHANGELOG>
# 
# Version 1.3.1 (20 May 2019)
# - Corrected bug when deploying changelog:w
# 
# Version 1.3.0 (20 May 2019)
# - Added :archive: (archive root definition)
# - Added optional :pre: and :post: steps to :deploy: definition
# 
# Version 1.2.8 (20 May 2019)
# - Updated Git tag/commit behaviour -- now commit/tag/push by default
# - Updated deploy to remove existing targets and copy entire directory trees
# 
# Version 1.2.7 (17 May 2019)
# - 'deploy' now expands '~' in paths
# 
# Version 1.2.6 (17 May 2019)
# - Updated deploy to use default dest from yaml (if specified)
# 
# Version 1.2.5 (07 Nov 2018)
# - Added 'deploy' command
# 
# Version 1.2.4 (05 Sep 2018)
# - Added commit message and tag details to `revision info`
# - Minor refactoring
# 
# Version 1.2.3 (03 Sep 2018)
# - Tidied up `revision info` output formatting
# 
# Version 1.2.2 (03 Sep 2018)
# - Updated CLI to provide version info
# 
# Version 1.2.1 (03 Sep 2018)
# - Update to allow releasable without any artefacts
# 
# Version 1.2.0 (06 Mar 2018)
# - Build definition improvements (and new yaml structure)
# - Added platform-agnostic environment variable definition (handles '~' replacement and :/; path separators)
# - Added platform-agnostic packaging of binaries (i.e. appending .exe for windows when archiving)
# 
# Version 1.1.10 (16 Feb 2018)
# - Modified 'archive' command to just archive existing artefact -- i.e. skip build phase
# - Added 'package' command that builds AND archives
# 
# Version 1.1.9 (16 Feb 2018)
# - Fixed bug when adding first changelog entry to file without existing placeholders
# - Added standalone build command
# 
# Version 1.1.8 (15 Dec 2017)
# - Added .yardopts to build documentation
# 
# Version 1.1.7 (15 Dec 2017)
# - Corrected push -- was pushing tags without commit
# 
# Version 1.1.6 (15 Dec 2017)
# - Added full changelog entry as tag message
# - Removed ruby-git dependency from gemspec
# 
# Version 1.1.5 (15 Dec 2017)
# - Replaced ruby-git library with shell calls, as wasn't handling submodules correctly
# 
# Version 1.1.4 (14 Dec 2017)
# - Minor message body reformatting
# 
# Version 1.1.3 (14 Dec 2017)
# - Eliminated duplication of version ID in commit message body
# 
# Version 1.1.2 (14 Dec 2017)
# - Removed redundant ':: ' from commit message headline
# 
# Version 1.1.1 (14 Dec 2017)
# - Added git connection failure handling
# - Revision commit message now includes first line of changelog entry
# - Updated configuration syntax for consistency (:revision: :file: -> :revision: :src:)
# 
# Version 1.1.0 (13 Dec 2017)
# - Updated to optionally push tags to the repo
# 
# Version 1.0.1 (13 Dec 2017)
# - Corrected revision placeholder handling when archiving build artefacts
# - Added proper high-level usage documentation
# 
# Version 1.0.0 (12 Dec 2017)
# - First fully functional release with new config file
# 
# Version 0.1.4 (12 Dec 2017)
# - boo
# - hoo
# - hoo
# 
# Version 0.1.3 (12 Dec 2017)
# - boo
# 
# Version 0.1.2 (12 Dec 2017)
# - wahoo!
# 
# Version 0.1.1 (12 Dec 2017)
# - Wahey!
# <END CHANGELOG>