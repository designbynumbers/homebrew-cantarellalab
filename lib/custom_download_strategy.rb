require "download_strategy"

class GitLFSDownloadStrategy < GitDownloadStrategy
  def fetch(timeout: nil)
    # Ensure Homebrew's bin directory is first in PATH so git-lfs can be found
    ENV["PATH"] = "#{HOMEBREW_PREFIX}/bin:#{ENV["PATH"]}"
    
    # Verify git-lfs is available
    unless system("git", "lfs", "version", out: File::NULL, err: File::NULL)
      odie <<~EOS
        git-lfs is required but not found. Please install it first:
        
          brew install git-lfs
          git lfs install
          
        Then retry: brew install cantarellalab/cantarellalab/knoodle
      EOS
    end
    
    super
  end
end
