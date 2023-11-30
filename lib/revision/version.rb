# Defines the revision ID for the revision gem
module Revision
  VERSION = "2.0.1".freeze
end

# <BEGIN CHANGELOG>
#
# Version 2.0.1 (30 Nov 2023)
# - deps(thor): Relaxed version dep from ~>1.0 to >=0.14
#
# Version 2.0.0 (10 Nov 2023)
# - new(checksum): Now using SHA512 rather than MD5 checksums
#
# Version 1.6.1 (31 Aug 2022)
# - Fixed logging error preventing windows exe creation
#
# Version 1.6.0 (01 Dec 2021)
# - New feature: Automated checksum generation during 'archive' and 'deploy' tasks
#
# Version 1.5.3 (26 Oct 2021)
# - Multiple deployment destinations bugfix -- only last destination was being used.
#
# Version 1.5.2 (10 Jun 2020)
# - Uprevving around undeletable git tag
#
## Version 1.5.1 (10 Jun 2020)
# - Escape " and ' in commit message when constructing git command line (' still problematic in some shells)
#
# Version 1.5.0 (13 Feb 2020)
# - Now handles multiple deployment destinations in releasables.yaml
#
# Version 1.4.1 (18 Nov 2019)
# - Updated to strip trailing whitespace after comment char for empty line
#
# Version 1.4.0 (10 Jun 2019)
# - Now allow the definition of one or more 'secondary_revisions', where a revision ID can be updated with or without an embedded changelog
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
