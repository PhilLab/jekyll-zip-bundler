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
    CACHE_FOLDER = '.jekyll-cache/zip_bundler/'

    def initialize(tag_name, markup, tokens)
      super
      # Split by spaces but only if the text following contains an even number of '
      # Based on https://stackoverflow.com/a/11566264
      # Extended to also not split between the curly brackets of Liquid
      # In addition, make sure the strings are stripped and not empty
      @files = markup.strip.split(/\s(?=(?:[^'}]|'[^']*'|{{[^}]*}})*$)/)
                     .map(&:strip)
                     .reject(&:empty?)
    end

    def render(context)
      # First file is the target zip archive path
      target, files = resolve_parameters(context)
      abort 'zip tag must be called with at least two files' if files.empty?

      zipfile_path = CACHE_FOLDER + target
      FileUtils.makedirs(File.dirname(zipfile_path))

      # Create the archive. Delete file, if it already exists
      File.delete(zipfile_path) if File.exist?(zipfile_path)
      Zip::File.open(zipfile_path, Zip::File::CREATE) do |zipfile|
        files.each do |file|
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
                                                  File.dirname(target),
                                                  File.basename(zipfile_path))
      # No rendered output
      ''
    end

    private_class_method def resolve_parameters(context)
      # Resolve the given parameters to a file list
      target, files = @files.map do |file|
        next file unless file.match(VARIABLE_SYNTAX)

        # This is a variable. Look it up.
        context[file]
      end

      [target, files]
    end
  end
end

Liquid::Template.register_tag('zip', Jekyll::ZipBundlerTag)
