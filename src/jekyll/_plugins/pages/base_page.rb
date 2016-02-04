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
    #alias superpath path

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
      self.read_yaml(File.join("content", @langcode, @dir), @name)

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
        LogHelper.log(
          "Warning",
          "A translated page doesn\'t have an updated_on field. " +
          File.join(@langcode, self.relative_path)
        )
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

  # This is called when the main generator has finished creating pages
  # def onBuildComplete()
  #   autogenerateBetterBook()
  # end

  # Force generation is used when you are in a section that isn't published
  # i.e. styleguide shouldn't be in the menu for fundamentals, but if you
  # are on /web/styleguide/ the menu should have styleguide at the top level
  # def getBetterBookEntry(section, currentLevel, forceGeneration = false, isSelected = false)
  #  if section.nil?
  #    return nil
  #  end
  #
  #  if section['index'].nil?
  #    return nil
  #  end
  #
  #  indexPage = getAppropriatePage(section['index'])
  #  if (!forceGeneration) && (indexPage['published'] == false)
  #    return nil
  #  end
  #
  #  entry = {
  #    "title" => indexPage['title'],
  #    "path" => indexPage.relativeUrl,
  #    "currentPageInThisSection" => false,
  #    "isSelected" => isSelected
  #  }
  #
  #  if (@directories.size > currentLevel) && (section['id'] == @directories[currentLevel])
  #    if (currentLevel + 1 == @directories.size)
  #      entry['currentPageInThisSection'] = true;
  #    end
  #    entry['section'] = getBetterBookSections(section, (currentLevel + 1))
  #    entry['hasSubNav'] = entry['section'].size > 0
  #  end
  #
  #  entry
  #end

  #def getBetterBookSections(currentSection, currentLevel)
  #  sections = []
  #
  #  # Iterate over each sub section
  #  currentSection['subdirectories'].each { |subdirectory|
  #    # Subdirectory entry
  #    entry = getBetterBookEntry(subdirectory, currentLevel)
  #    if entry.nil?
  #      next
  #    end
  #
  #    sections << entry
  #  }
  #
  #  sections
  #end

  # Generate the better book used for menus
  #def autogenerateBetterBook()
  #  context = self.data['_context']
  #  if context.nil?
  #    msg = 'self.data[\'_context\'] is nil in (' + relative_path + ')'
  #    raise Exception.new("Unable to generate better book: " + msg);
  #    return
  #  end
  #
  #  currentLevel = 0
  #  topLevelEntries = []
  #
  #  # Pick out this pages rootSection and split out other sections
  #  site.data['_context']['subdirectories'].each { |subdirectory|
  #    if subdirectory['index'].nil?
  #      next
  #    end
  #
  #    # We force generation here since if you in a top level section
  #    # we want the nav to be generated for that page, regardless of whether
  #    # it's normally displayed or not
  #    force = false
  #    isSelected = false
  #    if subdirectory['id'] == @directories[currentLevel]
  #      isSelected = true
  #      if @directories.count > 0
  #        force = true
  #      end
  #    end
  #    entry = getBetterBookEntry(subdirectory, currentLevel, force, isSelected)
  #    if entry.nil?
  #      next
  #    end
  #
  #    topLevelEntries << entry
  #  }
  #
  #  self.data['contentnav'] = { "toc" => topLevelEntries }
  #end

  # This method will try and find the translated version of a page
  # If the translation isn't available, it'll return the english version
  #def getAppropriatePage(page)
  #  if page.nil?
  #    return nil
  #  end
  #
  #  bestPage = page
  #  if page.langcode != @langcode
  #    page.data['translations'].each { |lcode, translationPage|
  #      if translationPage.langcode == @langcode
  #        bestPage = translationPage
  #        break
  #      end
  #    }
  #  end
  #
  #  bestPage
  #end

  #def context
  #  if self.data['_context'].nil?
  #    return
  #  end
  #
  #  langSpecificContenxt = generateValidVersion(self.data['_context'])
  #  langSpecificContenxt
  #end

  #def generateValidPages(pages)
  #  returnedPages = []
  #  pages.each { |page|
  #    bestPage = getAppropriatePage(page)
  #    if(page.data['published'] != false)
  #      returnedPages << bestPage
  #    end
  #  }
  #  return returnedPages
  #end

  #def generateValidSubdirectories(subdirectories)
  #  validSubdirectories = []
  #  subdirectories.each { |subdirectory|
  #    validSubdirectories << generateValidVersion(subdirectory)
  #  }
  #  return validSubdirectories
  #end

  #def generateValidVersion(sectionObj)
  #  validObj = {
  #    "id" => sectionObj['id'],
  #    "index" => nil,
  #    "pages" => [],
  #    "subdirectories" => []
  #  }
  #
  #  validObj['index'] = getAppropriatePage(sectionObj['index'])
  #  validObj['pages'] = generateValidPages(sectionObj['pages'])
  #  validObj['subdirectories'] = generateValidSubdirectories(sectionObj['subdirectories'])
  #  return validObj
  #end

  #def path
  #  return File.join(site.config['WFContentSource'], @langcode, @dir, @name)
  #end

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
      %w[ outOfDate ])
  end
  end
end
