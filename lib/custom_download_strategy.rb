require "download_strategy"

class GitLFSDownloadStrategy < GitDownloadStrategy
  def fetch(timeout: nil)
    # Ensure Homebrew's bin directory is first in PATH so git-lfs can be found
    ENV["PATH"] = "#{HOMEBREW_PREFIX}/bin:#{ENV["PATH"]}"
    
    # Verify git-lfs is available
    unless system("git", "lfs", "version", out: File::NULL, err: File::NULL)
      # Make error message more prominent with clear separation
      puts "\n" + "="*60
      puts "KNOODLE INSTALLATION REQUIRES GIT LFS"
      puts "="*60
      odie <<~EOS
        Git LFS is required but not found. Please install it first:
        
          brew install git-lfs
          git lfs install
          
        Then retry the installation:
        
          brew install knoodle
        
        (If you haven't added the tap yet, run: brew tap designbynumbers/cantarellalab)
      EOS
    end
    
    super
  end
end
