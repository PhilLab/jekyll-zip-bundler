# frozen_string_literal: true

# Copyright 2021 by Philipp Hasper
# MIT License
# https://github.com/PhilLab/jekyll-zip-bundler

require 'jekyll'
require 'zip'
# ~ gem 'rubyzip', '~>2.3.0'

module Jekyll
  # Valid syntax:
  # {% zip archiveToCreate.zip file1.txt file2.txt %}
  # {% zip archiveToCreate.zip file1.txt folder/file2.txt 'file with spaces.txt' %}
  # {% zip {{ variableName }} file1.txt 'folder/file with spaces.txt' {{ otherVariableName }} %}
  # {% zip {{ variableName }} {{ VariableContainingAList }} %}
  class ZipBundlerTag < Liquid::Tag
    VARIABLE_SYNTAX = /[^{]*(\{\{\s*[\w\-.]+\s*(\|.*)?\}\}[^\s{}]*)/mx.freeze

    def initialize(tag_name, markup, tokens)
      super
      # Split by spaces but only if the text following contains an even number of '
      # Based on https://stackoverflow.com/a/11566264
      # Extended to also not split between the curly brackets of Liquid
      @files = markup.strip.split(/\s(?=(?:[^'}]|'[^']*'|{{[^}]*}})*$)/)
    end

    def render(context)
      files = []
      # Resolve the given parameters to a file list
      @files.each do |file|
        matched = file.strip.match(VARIABLE_SYNTAX)
        if matched
          # This is a variable. Look it up.
          resolved = context[file]
          if resolved.respond_to?(:each)
            # This is a collection. Flatten it before appending
            resolved.each do |resolved_file|
              files.push(resolved_file)
            end
          else
            files.push(resolved)
          end
        elsif file.strip.length.positive?
          files.push(file.strip)
        end
      end

      # First file is the target zip archive path
      abort 'zip tag must be called with at least two files' if files.length < 2
      # Generate the file in the cache folder
      cache_folder = '.jekyll-cache/zip_bundler/'
      zipfile_path = cache_folder + files[0]
      FileUtils.makedirs(File.dirname(zipfile_path))

      files_to_zip = files[1..-1]

      # Create the archive. Delete file, if it already exists
      File.delete(zipfile_path) if File.exist?(zipfile_path)
      Zip::File.open(zipfile_path, Zip::File::CREATE) do |zipfile|
        files_to_zip.each do |file|
          # Two arguments:
          # - The name of the file as it will appear in the archive
          # - The original file, including the path to find it
          zipfile.add(File.basename(file), file)
        end
      end
      puts "Created archive #{zipfile_path}"

      # Add the archive to the site's static files
      site = context.registers[:site]
      site.static_files << Jekyll::StaticFile.new(site, "#{site.source}/#{cache_folder}",
                                                  File.dirname(files[0]),
                                                  File.basename(zipfile_path))
      # No rendered output
      ''
    end
  end
end

Liquid::Template.register_tag('zip', Jekyll::ZipBundlerTag)
