require "download_strategy"

class GitLFSDownloadStrategy < GitDownloadStrategy
  def clone_repo
    # Ensure git-lfs is available
    unless which("git-lfs")
      system "brew", "install", "git-lfs" unless quiet_system "git-lfs", "version"
    end
    
    # Initialize git-lfs
    safe_system "git", "lfs", "install", "--local"
    
    super
  end

  def checkout
    super
    
    # Pull LFS files after checkout
    in_cache do
      safe_system "git", "lfs", "pull"
    end
  end

  private

  def which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each { |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable?(exe) && !File.directory?(exe)
      }
    end
    return nil
  end
end
