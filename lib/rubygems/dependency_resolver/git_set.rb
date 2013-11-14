##
# A GitSet represents gems that are sourced from git repositories.
#
# This is used for gem dependency file support.
#
# Example:
#
#   set = Gem::DependencyResolver::GitSet.new
#   set.add_git_gem 'rake', 'git://example/rake.git', tag: 'rake-10.1.0'

class Gem::DependencyResolver::GitSet < Gem::DependencyResolver::Set

  ##
  # A Hash containing git gem names for keys and a Hash of repository and
  # git commit reference as values.

  attr_reader :repositories # :nodoc:

  ##
  # A hash of gem names to Gem::DependencyResolver::GitSpecifications

  attr_reader :specs # :nodoc:

  def initialize # :nodoc:
    @git          = ENV['git'] || 'git'
    @repositories = {}
    @specs        = {}
  end

  def add_git_gem name, repository, reference # :nodoc:
    @repositories[name] = [repository, reference]
  end

  ##
  # Finds all git gems matching +req+

  def find_all req
    @repositories.keys.select do |name|
      name == req.name
    end.map do |name|
      @specs[name] || load_spec(name)
    end.select do |spec|
      req.matches_spec? spec
    end
  end

  def load_spec name
    repository, reference = @repositories[name]

    source = Gem::Source::Git.new name, repository, reference

    spec = source.load_spec name

    git_spec =
      Gem::DependencyResolver::GitSpecification.new self, spec, source

    @specs[name] = git_spec
  end

  ##
  # Prefetches specifications from the git repositories in this set.

  def prefetch reqs
    names = reqs.map { |req| req.name }

    @repositories.each_key do |name|
      next unless names.include? name

      load_spec name
    end
  end

end

