require "download_strategy"

class GitLFSDownloadStrategy < GitDownloadStrategy
  def fetch(timeout: nil)
    puts "🔍 [GitLFS] Starting download with custom strategy..."
    
    # Preserve user environment that Git LFS might need
    original_home = ENV["HOME"]
    original_user = ENV["USER"]
    original_git_config = ENV.select { |k, v| k.start_with?("GIT_") }
    
    # Ensure Homebrew's bin directory is first in PATH
    ENV["PATH"] = "#{HOMEBREW_PREFIX}/bin:#{ENV["PATH"]}"
    puts "🔍 [GitLFS] PATH set to: #{ENV["PATH"]}"
    
    # Restore important environment variables that might have been sanitized
    ENV["HOME"] = original_home if original_home
    ENV["USER"] = original_user if original_user
    original_git_config.each { |k, v| ENV[k] = v }
    
    # Set up Git LFS environment explicitly
    ENV["GIT_LFS_SKIP_SMUDGE"] = "1"  # Skip smudge initially, let git lfs pull handle it
    
    puts "🔍 [GitLFS] Checking git-lfs availability..."
    
    # Verify git-lfs is available with more detailed check
    unless system("git", "lfs", "version", out: File::NULL, err: File::NULL)
      puts "❌ [GitLFS] git-lfs not found in PATH"
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
    
    puts "✅ [GitLFS] git-lfs found and working"
    puts "🔍 [GitLFS] Calling parent Git download strategy..."
    
    # Call the parent GitDownloadStrategy with timeout
    begin
      super
      puts "🔍 [GitLFS] Base git clone completed, now pulling LFS files..."
      
      # Explicitly pull LFS files after clone
      system("git", "lfs", "pull", chdir: cached_location.to_s, 
             exception: false, out: $stdout, err: $stderr)
      puts "✅ [GitLFS] LFS files downloaded successfully"
      
      # Fix submodule SSH URLs by directly modifying .gitmodules file (more reliable than git config)
      gitmodules_path = File.join(cached_location.to_s, ".gitmodules")
      if File.exist?(gitmodules_path)
        puts "🔍 [GitLFS] Converting SSH submodule URLs to HTTPS in .gitmodules..."
        
        # Read and modify .gitmodules file
        gitmodules_content = File.read(gitmodules_path)
        original_content = gitmodules_content.dup
        
        # Replace SSH URLs with HTTPS URLs
        gitmodules_content.gsub!(/git@github\.com:([^\/]+\/[^\/\s]+)(\.git)?/, 'https://github.com/\1')
        gitmodules_content.gsub!(/ssh:\/\/git@github\.com\/([^\/\s]+)/, 'https://github.com/\1')
        
        # Write back if changes were made
        if gitmodules_content != original_content
          File.write(gitmodules_path, gitmodules_content)
          puts "✅ [GitLFS] Converted SSH URLs to HTTPS in .gitmodules"
          
          # Show what we changed (for debugging)
          puts "🔍 [GitLFS] URL conversions made:"
          original_content.each_line.with_index do |line, idx|
            new_line = gitmodules_content.lines[idx]
            if line != new_line && line.include?("url =")
              puts "   #{line.strip} → #{new_line.strip}"
            end
          end
        else
          puts "ℹ️  [GitLFS] No SSH URLs found in .gitmodules - no conversion needed"
        end
      else
        puts "ℹ️  [GitLFS] No .gitmodules file found - no submodule conversion needed"
      end
      
    rescue => e
      puts "❌ [GitLFS] Download failed: #{e.message}"
      puts "🔍 [GitLFS] Current directory: #{Dir.pwd}"
      puts "🔍 [GitLFS] Cached location: #{cached_location}"
      raise
    end
  end
end
