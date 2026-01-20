require "download_strategy"

class GitLFSDownloadStrategy < GitDownloadStrategy
  def fetch(timeout: nil)
    # Ensure git-lfs is available
    unless system("which", "git-lfs", out: File::NULL, err: File::NULL)
      system "brew", "install", "git-lfs"
    end
    
    # Initialize git-lfs globally if not already done
    system "git", "lfs", "install", out: File::NULL, err: File::NULL
    
    super
  end

  def stage
    super
    
    # Pull LFS files after staging
    if cached_location.exist? && (cached_location/".git").exist?
      system "git", "-C", cached_location.to_s, "lfs", "pull", out: File::NULL, err: File::NULL
    end
  end
end
