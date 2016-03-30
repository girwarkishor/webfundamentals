# Copyright 2014 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Jekyll

  require 'sanitize'
  require File.expand_path('../../helpers/log.rb', __FILE__)

  class BasePage < Page

    DEFAULT_HEAD_TITLE = 'Web - Google Developers'
    DEFAULT_HEAD_DESCRIPTION = 'Google Developers - Web Fundamentals';

    alias superdest destination

    attr_reader :langcode

    def initialize(site, relativeDir, filename, langcode, addtionalYamlKeys=[], leafNode)

      self.data = self.data ? self.data : {}

      # IMPORTANT
      # @base, @dir and @name are used by Jekyll
      @base = File.join(Dir.pwd, site.config['WFContentSource'])
      @dir  = relativeDir
      @name = filename

      @site = site
      @leafNode = leafNode

      @directories = relativeDir.split(File::SEPARATOR)
      @addtionalYamlKeys = addtionalYamlKeys
      @langcode = langcode
      @defaultValidKeys = [
        'layout', 'title', 'description', 'order', 'translation_priority',
        'authors', 'translators', 'comments', 'published_on', 'updated_on',
        'published', 'rss', 'comments', 'key-takeaways', 'notes',
        'related-guides', 'html_head_social_img', 'feedName', 'feedURL',
        'pageGroups'
      ]

      # This is a Jekyll::Page method
      # (See: http://www.rubydoc.info/github/mojombo/jekyll/Jekyll/Page#process-instance_method)
      self.process(filename)

      initialisePage()

      # These parameters can be overwritten by pages that extend BasePage
      self.data['html_css_file'] = site.config['WFBaseUrl'] + '/styles/fundamentals.css';
      self.data['strippedDescription'] = Sanitize.fragment(self.data['description'])
      self.data['theme_color'] = '#CFD8DC'
      self.data['langcode'] = @langcode

      # self.data['translations'] = {}
      #
      # The root of /web/ has an rss feed, this if accounts for that
      # self.data['feed_name'] = 'Web - Google Developers'
      #if @directories.count > 0
      #  self.data['rss_feed_url'] = File.join(site.config['WFBaseUrl'], @directories[0], 'rss.xml')
      #  self.data['atom_feed_url'] = File.join(site.config['WFBaseUrl'], @directories[0], 'atom.xml')
      #else
      #  self.data['rss_feed_url'] = File.join(site.config['WFBaseUrl'], 'rss.xml')
      #  self.data['atom_feed_url'] = File.join(site.config['WFBaseUrl'], 'atom.xml')
      #end
    end

    def initialisePage()
      # We know the files live in content/<langname>/<relative directory>/
      if (File.exists? File.join("content", @langcode, @dir, @name))
        self.read_yaml(File.join("content", @langcode, @dir), @name)
      end

      # Check that all the keys in the YAML data is valid
      validateYamlData()

      # Initialise canoncial and relative URLS
      initialiseUrls()

      self.data["rtl"] = false
      if site.data["language_names"][@langcode].has_key?("rtl")
        self.data["rtl"] = site.data["language_names"][@langcode]["rtl"];
      end

      if self.data['html_head_title'].nil?
        # There is no html_head_title defined in the YAML
        if self.data['title'].nil?
          self.data['html_head_title'] = self.class::DEFAULT_HEAD_TITLE
        else
          self.data['html_head_title'] = self.data['title'] +
            ' | ' + self.class::DEFAULT_HEAD_TITLE
        end
      end

      if self.data['html_head_description'].nil?
        # There is no html_head_description defined in the YAML
        if self.data['description'].nil?
          self.data['html_head_description'] = self.class::DEFAULT_HEAD_DESCRIPTION
        else
          self.data['html_head_description'] = self.data['description']
        end
      end

      if self.data['html_head_social_img'].nil?
        self.data['html_head_social_img'] =  site.config['WFBaseUrl'] + '/imgs/logo.png'
      end
    end

    # This method checks for any invalid or disallowed fields in the
    # YAML of a file
    def validateYamlData()
      # If this is a translation, we need to remove fields copied over from
      # english yaml during the jekyll generation
      if @langcode != site.config['primary_lang']
        primaryLangOnlyKeys = [
          'order',
          'layout',
          'authors',
          'published_on'
        ]
        primaryLangOnlyKeys.each { |key|
          if @defaultValidKeys.include?(key)
            @defaultValidKeys.delete(key)
          end
        }
      end

      # Merge keys from constructor
      allowedKeys = @defaultValidKeys + @addtionalYamlKeys

      invalidKeys = []
      self.data.each do |key, value|
        if not allowedKeys.include? key
          invalidKeys << key
        end
      end

      if invalidKeys.length > 0
        LogHelper.throwError(
          invalidKeys.length.to_s + " invalid YAML keys found in " +
          File.join(@langcode, self.relative_path) + " " +
          "[" + invalidKeys.join(",") + "]"
        )
      end

      # Check authors are valid
      if self.data.has_key?('authors') and (self.data['authors'].length > 0)
        self.data['authors'].each { |authorKey|
          if site.data['contributors'][authorKey].nil?
            LogHelper.throwError(
              "Invalid author '" + authorKey + "' in YAML in " +
              File.join(@langcode, self.relative_path) + ". " +
              "Please ensure this author is in the contributors.yaml"
            )
          end
        }
      end
    end

    def initialiseUrls()
      # Example cleanUrl: /web/section/example
      cleanUrl = site.config['WFBaseUrl'] + self.url
      cleanUrl = cleanUrl.sub('index.html', '')
      cleanUrl = cleanUrl.sub('.html', '')

      # WARNING: This is intended for use in the head of the document only
      # it doesn't include the hl
      # Output Example: https://developers.google.com/web/section/example
      self.data["noLanguageCanonicalUrl"] = site.config['WFAbsoluteUrl'] + cleanUrl

      # The canonicalUrl can be used to reference a pages absolute url with the
      # appropriate lang code
      # Output Example: https://developers.google.com/web/section/example?hl=<lang>
      self.data["canonicalUrl"] = self.data["noLanguageCanonicalUrl"] + "?hl=" + @langcode

      # The relativeUrl can be used to reference a pages relative url with the
      # appropriate lang code
      # Output Example: /web/section/example?hl=<lang>
      self.data["relativeUrl"] = cleanUrl + "?hl=" + @langcode || site.config['primary_lang']
    end

    def nextPage
      # getAppropriatePage(self.data['_nextPage'])
      if defined?(@_nextPage)
        return @_nextPage
      end

      @_nextPage = TreeHelper.getNextPage(@leafNode, @langcode)
      return @_nextPage
    end

    def previousPage
      # getAppropriatePage(self.data['_previousPage'])
      if defined?(@_prevPage)
        return @_prevPage
      end

      @_prevPage = TreeHelper.getPrevPage(@leafNode, @langcode)
      return @_prevPage
    end

    def siblingPages
      if defined?(@_siblingPages)
        return @_siblingPages
      end

      @_siblingPages = TreeHelper.getSiblingPages(@leafNode.getParent(), @langcode)
      return @_siblingPages
    end

    def subdirectories
      if defined?(@_subdirectoires)
        return @_subdirectoires
      end

      @_subdirectoires = TreeHelper.getSubdirectories(@leafNode.getParent(), @langcode)
      return @_subdirectoires
    end

    def parentDirectoryId
      if defined?(@_parentDirectoryId)
        return @_parentDirectoryId
      end

      @_parentDirectoryId = TreeHelper.getBranchId(@leafNode.getParent())
      return @_parentDirectoryId
    end

    def outOfDate
      if defined?(@_outOfDate)
        return @_outOfDate
      end

      # Set a default value
      @_outOfDate = false

      # Only translated pages can be out of date (treat primary lang as true src)
      if self.langcode == site.config['primary_lang']
        return @_outOfDate
      end

      if !(self.data.has_key?('updated_on'))
        #LogHelper.log(
        #  "Warning",
        #  "A translated page doesn\'t have an updated_on field. " +
        #  File.join(@langcode, self.relative_path)
        #)
        return @_outOfDate
      end

      primaryLangPage = @leafNode.getPageForLang(site.config['primary_lang'])
      if !(primaryLangPage.data.has_key?('updated_on'))
        LogHelper.throwError(
          "A translation file has an updated_on while the primary language version doesn't have an updated_on field. Please add one to: " +
          File.join('en', self.relative_path)
        )
      end

      @_outOfDate = (self.data['updated_on'] < primaryLangPage.data['updated_on'])

      return @_outOfDate
    end

    def generateNavigationList(rootToLeafBranches, currentLevel)
      navigationPageList = []

      currentBranchInPath = rootToLeafBranches[currentLevel]
      nextBranchInPath = rootToLeafBranches[currentLevel + 1]

      currentBranchInPath.getBranchNodes().each { |branchNode|
        indexPage = nil
        indexLeafNode = TreeHelper.getIndexLeafNode(branchNode)
        if !(indexLeafNode.nil?)
          navigationPageList << {
            "page" => indexLeafNode.getPageForLang(@langcode),
            "isSelected" => (branchNode == nextBranchInPath),
            "navigationLevel" => currentLevel + 1
          }
        end

        if branchNode == nextBranchInPath && (currentLevel + 1 < rootToLeafBranches.size)
          # minus one since the root branch doesnt count
          navigationPageList.concat(generateNavigationList(rootToLeafBranches, currentLevel + 1))
        end
      }

      if nextBranchInPath.nil?
        # We are at the end of the branch list, should we add other child pages?
        leafNodes = currentBranchInPath.getLeafNodes()
        leafNodes.each { |leafNode|
          if leafNode.isIndexLeaf
            next
          end

          navigationPageList << {
            "page" => leafNode.getPageForLang(@langcode),
            "isSelected" => (leafNode.getPageForLang(@langcode) == self),
            "navigationLevel" => currentLevel + 2
          }
        }
      end

      return navigationPageList
    end

    def navigation
      if defined?(@_navigation)
        return @_navigation
      end

      rootBranchToLeaf = TreeHelper.getRootToLeafPath(@leafNode)
      if (rootBranchToLeaf.size > 0)
        @_navigation = generateNavigationList(rootBranchToLeaf, 0)
      else
        @_navigation = []
      end

      return @_navigation
    end

    def translations
      return @leafNode.translatedPages
    end

  # This is a method from the Jekyll::Page class
  def path
    return File.join(site.config['WFContentSource'], @langcode, @dir, @name)
  end

  # This is a method from the Jekyll::Page class
  # http://www.rubydoc.info/github/mojombo/jekyll/master/Jekyll/Page
  def relative_path
    return File.join(@dir, @name)
  end

  # This is a method from the Jekyll::Page class
  # http://www.rubydoc.info/github/mojombo/jekyll/master/Jekyll/Page
  # This points the destation to a nested language if appropriate
  def destination(dest)
    original_target = Pathname.new self.superdest("")
    base = Pathname.new dest
    relativePath = original_target.relative_path_from base
    return File.join(base, @langcode, relativePath)
  end

  # Convert this post into a Hash for use in Liquid templates.
  #
  # Returns <Hash>
  def to_liquid(attrs = ATTRIBUTES_FOR_LIQUID)
    super(attrs +
      %w[ parentDirectoryId ] +
      %w[ siblingPages ] +
      %w[ subdirectories ] +
      %w[ nextPage ] +
      %w[ previousPage ] +
      %w[ outOfDate ] +
      %w[ navigation ] +
      %w[ translations ]
    )
  end
  end
end
