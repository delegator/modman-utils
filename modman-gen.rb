#!/usr/bin/env ruby
require 'find'

$ignored_files = %w(.gitignore Gruntfile.js modman package.json README.md README)
$ignored_dirs = %w(.git)

# Finds unique directories that exist in the first path, but not the second.
#
# first - String path to a directory.
# second - String path to another directory.
#
# Examples
#
#   # Given the following directory structure:
#   a/
#     foo/
#       bar/
#       baz/
#   b/
#     foo/
#       bar/
#       qux/
#
#   find_unique_directories('./a', './b')
#   # => ["/foo/baz"]
#
# Returns Array<String>, each item representing a path (leading directory component omitted).
def find_unique_directories(first, second)
  directory_list = []
  Find.find(first) do |dir|
    next if dir == first
    relative_dir = dir.gsub(/#{first}/, '')
    Find.prune if $ignored_dirs.include? relative_dir
    next unless FileTest.directory?(dir)

    # test for this directory in the 'second' directory
    relative_dir = dir.gsub(/#{first}/, '')
    unless FileTest.directory?(second + relative_dir)
      directory_list << relative_dir
      Find.prune
    end
  end

  directory_list
end

# Finds unique files that exist in the first path, but not the second. Files that exist in the 'exclude' path will be omitted.
#
# first - String path to a directory.
# exclude - Array<String> paths of directories, files contained in any of these directories will be excluded from the resulting output.
#
# Examples
#
#   # Given the following directory/file structure:
#   a/
#     bar/
#       fileone
#       filetwo
#     foo/
#       filethree
#   b/
#     bar/
#       fileone
#     qux/
#       filefour
#
#   find_unique_files('./a', ['/bar'])
#   # => ["/foo/filethree"]
#
# Returns Array<String>, each item representing a path (leading directory component omitted).
def find_unique_files(first, exclude)
  file_list = []
  Find.find(first) do |file|
    relative_file_path = file.gsub(/#{first}/, '')
    next if $ignored_files.include? relative_file_path
    next if file == first
    relative_dir = file.gsub(/#{first}/, '')
    Find.prune if $ignored_dirs.include? relative_dir
    next if FileTest.directory?(file)
    # Make sure this file isn't in a path in the 'exclude' array
    exclude_file = false
    exclude.each do |dir|
      if relative_file_path =~ /^#{dir}/
        exclude_file = true
        break
      end
    end
    unless exclude_file
      file_list << relative_file_path
    end
  end

  file_list
end

# Converts many globbable paths to a globbed modman entries
#
# paths - An Array<String> containing multiple paths.
#
# Examples
#
#   paths = %w(app/code/Community/Bar app/code/Community/Baz app/code/Community/Foo 123.php)
#   globify_and_format(paths)
#   # => ["app/code/community/*\tapp/code/community/", "123.php\t123.php"]
#
# Returns Array<String> paths as modman entries. The +paths+ argument is also modified.
def globify_and_format(paths)
  # Alphabetize our paths before getting started.
  paths.sort!

  paths.each_index do |index|
    total_paths = paths.count
    path_exploded = paths[index].split('/')
    path_exploded.delete_at(-1)
    path = path_exploded.join('/')
    globbed = []
    unless path == ''
      ((index + 1)..(total_paths - 1)).to_a.each do |i|
        i_exploded = paths[i].split('/')
        i_exploded.delete_at(-1)
        i_path = i_exploded.join('/')
        if i_path === path
          globbed << i
        else
          # At this point, we've found all the "globbable" lines. We now need to check the next line to make sure that
          # our globbed path doesn't INCLUDE the next path when it expands.
          #
          # Example:
          # paths => {
          #   [0] => js/custom.js,
          #   [1] => js/main.js,
          #   [2] => js/helper.js,
          #   [3] => js/scriptaculous/custom.js,
          #   [4] => js/scriptaculous/helper.js
          # }
          #  === Becomes ===
          # paths => {
          #   [0] => js/*
          #   [1] => js/scriptaculous/*
          # }
          #
          # These two lines conflict, and may overwrite valid files. Instead, we SHOULDN'T glob if the next line is a
          # subdirectory.
          i_exploded.delete_at(-1)
          i_path = i_exploded.join('/')
          globbed = [] if i_path == path
          break
        end
      end
    end


    # convert paths to true modman-style entries
    # each entry is a simple 1-to-1 mapping
    if globbed.empty?
      paths[index] = paths[index] + "\t" + paths[index]
    else
      paths.slice!(globbed[0]..globbed[-1])
      paths[index] = path + "/*\t" + path + "/"
    end
  end
end

# Main program begin (only if called directly)
if __FILE__ == $0

  # Ensure that we are in a modman module directory
  directory = Dir.getwd.split('/')
  unless directory[-2] == '.modman'
    puts "It looks like you aren't in a Modman module directory. Exiting."
    exit 1
  end

  # Put together the 'module_directory' and 'target_directory' directories
  module_directory = directory.join('/') + '/'
  directory.delete_at(-2)
  directory.delete_at(-1)
  target_directory = directory.join('/') + '/'

  # Find all directories that exist in the module directory, but not the target directory
  uniq_directories = find_unique_directories(module_directory, target_directory)

  # Find all files that exist in the module directory, but not the target directory (already found in uniq_directories)
  uniq_files = find_unique_files(module_directory, uniq_directories)

  # Glob and format the directories and files
  modman_entries = uniq_directories + uniq_files
  globify_and_format(modman_entries)

  # Output the modman file
  modman_entries.each { |line| puts line }
end
