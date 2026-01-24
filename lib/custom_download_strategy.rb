require "download_strategy"

# Custom Git LFS download strategy for Knoodle
# Handles LFS files and converts SSH submodule URLs to HTTPS for systems without SSH keys
class KnoodleGitLFSDownloadStrategy < GitDownloadStrategy
  
  # Class constant to verify strategy is loaded
  STRATEGY_VERSION = "2.0.0"
  
  def self.loaded?
    true
  end
  
  def fetch(timeout: nil)
    ohai "[Knoodle] Custom download strategy v#{STRATEGY_VERSION} active"
    ohai "[Knoodle] Starting Git LFS download..."
    
    # Preserve environment that Git LFS might need
    original_home = ENV["HOME"]
    original_user = ENV["USER"]
    original_git_config = ENV.select { |k, _v| k.start_with?("GIT_") }
    
    # Ensure Homebrew's bin directory is first in PATH
    ENV["PATH"] = "#{HOMEBREW_PREFIX}/bin:#{ENV["PATH"]}"
    
    # Restore important environment variables that might have been sanitized
    ENV["HOME"] = original_home if original_home
    ENV["USER"] = original_user if original_user
    original_git_config.each { |k, v| ENV[k] = v }
    
    # Set up Git LFS environment explicitly
    # Skip smudge initially, let git lfs pull handle it after clone
    ENV["GIT_LFS_SKIP_SMUDGE"] = "1"
    
    # Verify git-lfs is available
    ohai "[Knoodle] Checking git-lfs availability..."
    git_lfs_found = system("git", "lfs", "version", out: File::NULL, err: File::NULL)
    
    unless git_lfs_found
      # Print diagnostic info before failing
      opoo "[Knoodle] git-lfs not found! Diagnostic info:"
      opoo "[Knoodle] PATH = #{ENV["PATH"]}"
      opoo "[Knoodle] HOMEBREW_PREFIX = #{HOMEBREW_PREFIX}"
      opoo "[Knoodle] which git-lfs = #{`which git-lfs 2>/dev/null`.strip}"
      
      odie <<~EOS
        
        ================================================================
        KNOODLE INSTALLATION REQUIRES GIT LFS
        ================================================================
        
        Git LFS is required but was not found. Please install it first:
        
          brew install git-lfs
          git lfs install
          
        Then retry the installation:
        
          brew install knoodle
        
        If you haven't added the tap yet, run:
          brew tap designbynumbers/cantarellalab
        
      EOS
    end
    
    ohai "[Knoodle] git-lfs found and working"
    ohai "[Knoodle] Calling parent Git download strategy..."
    
    # Call the parent GitDownloadStrategy
    begin
      super
      ohai "[Knoodle] Base git clone completed to: #{cached_location}"
      
      # Pull LFS files explicitly after clone
      ohai "[Knoodle] Pulling LFS files..."
      Dir.chdir(cached_location.to_s) do
        system("git", "lfs", "pull")
      end
      ohai "[Knoodle] LFS files downloaded"
      
      # Convert SSH submodule URLs to HTTPS
      # This is critical for WSL2/Linux systems without GitHub SSH keys
      convert_ssh_to_https_in_gitmodules(cached_location.to_s)
      
    rescue => e
      opoo "[Knoodle] Download failed: #{e.message}"
      opoo "[Knoodle] Cached location: #{cached_location}"
      raise
    end
  end
  
  private
  
  # Convert SSH URLs to HTTPS in .gitmodules file
  # This allows submodule cloning to work without SSH keys
  def convert_ssh_to_https_in_gitmodules(repo_path)
    gitmodules_path = File.join(repo_path, ".gitmodules")
    
    unless File.exist?(gitmodules_path)
      ohai "[Knoodle] No .gitmodules file found - no submodules to convert"
      return
    end
    
    ohai "[Knoodle] Converting SSH submodule URLs to HTTPS..."
    
    begin
      gitmodules_content = File.read(gitmodules_path)
      original_content = gitmodules_content.dup
      
      # Log what URLs we're starting with
      original_content.each_line do |line|
        ohai "[Knoodle] Found: #{line.strip}" if line.include?("url =")
      end
      
      # Pattern 1: git@github.com:user/repo.git or git@github.com:user/repo
      # Captures: user/repo (with optional .git)
      gitmodules_content.gsub!(
        %r{git@github\.com:([^/\s]+/[^/\s]+?)(\.git)?(\s|$)},
        'https://github.com/\1\3'
      )
      
      # Pattern 2: ssh://git@github.com/user/repo.git or ssh://git@github.com/user/repo
      # Note: This pattern correctly captures user/repo (two path components)
      gitmodules_content.gsub!(
        %r{ssh://git@github\.com/([^/\s]+/[^/\s]+?)(\.git)?(\s|$)},
        'https://github.com/\1\3'
      )
      
      if gitmodules_content != original_content
        File.write(gitmodules_path, gitmodules_content)
        ohai "[Knoodle] Converted SSH URLs to HTTPS:"
        
        # Show the conversions
        original_content.each_line.with_index do |line, idx|
          new_line = gitmodules_content.lines[idx]
          if line != new_line && line.include?("url =")
            ohai "[Knoodle]   #{line.strip}"
            ohai "[Knoodle]   => #{new_line&.strip}"
          end
        end
      else
        ohai "[Knoodle] No SSH URLs found in .gitmodules (already HTTPS or no submodules)"
      end
    rescue => e
      opoo "[Knoodle] Failed to process .gitmodules: #{e.message}"
      opoo "[Knoodle] Submodule cloning may fail if SSH keys aren't configured"
    end
  end
end
