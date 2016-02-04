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

  require File.expand_path('../helpers/log.rb', __FILE__)
  require File.expand_path('../pages/base_page.rb', __FILE__)
  require File.expand_path('../models/branch_node.rb', __FILE__)
  require File.expand_path('../models/leaf_node.rb', __FILE__)

  # This generator will find all the files in the
  # directory where all the markdown is stored
  # and create the site.data["translations"] map
  # which is used to track translations of a Page
  #
  # Define the source of the markdown by Setting
  # 'WFContentSource' in the config.yaml


  # Create pages for Jekyll to build and handle translations
  class MainGenerator < Generator
    priority :highest
    def generate(site)
      @contentSource = site.config["WFContentSource"]
      @absoluteUrl = site.config["WFAbsoluteUrl"]
      @primaryLang = site.config["primary_lang"]
      @langsAvailable = site.config["langs_available"]
      @markdownExtensions = [".markdown", ".md", ".html"]
      @site = site
      @contentFilepath = File.join(Dir.pwd, @contentSource)
      @initialPath = File.join(@contentFilepath, @primaryLang)
      @relativePath = ''
      @tree = BranchNode.new(nil, 'root')

      self.performInitialChecks()

      self.prepareInitialVariables(site)

      # Make the language code and matching language name available
      # to all of the site
      # site.data["primes"] = translations(site)




      traverseFilePath(@initialPath, @relativePath, @tree)
    end

    def performInitialChecks()
      if @contentSource.nil?
        LogHelper.throwError("WFContentSource is not defined - no " +
          "translations to map")
        return
      end

      if @absoluteUrl.nil?
        LogHelper.throwError("WFAbsoluteUrl is not defined in the config yaml")
        return
      end

      if @primaryLang.nil?
        LogHelper.throwError("primary_lang is not defined in the config yaml")
        return
      end

      if @langsAvailable.nil?
        LogHelper.throwError("langs_available is not defined in the config yaml")
        return
      end
    end

    def prepareInitialVariables(site)
      site.data["contributors"] = self.getContributors(site)
      site.data["language_names"] = YAML.load_file(site.config['WFLangNames'])

      if ENV.has_key?('WF_BUILD_LANG')
        @langsAvailable = [ENV['WF_BUILD_LANG']]
      end

      if ENV.has_key?('WF_BUILD_SECTION')
        @initialPath = File.join(@initialPath, ENV['WF_BUILD_SECTION'])
        @relativePath = File.join(@relativePath, ENV['WF_BUILD_SECTION'])
      end
    end

    def getContributors(site)
      contributorsFilepath = site.config['WFContributors']
      contributesData = YAML.load_file(contributorsFilepath)
      contributesData = contributesData.each { |contributerKey, contributorObj|
        # Check if contributor description exists and if so that it has en
        # translation
        if not contributorObj['description'].nil?
          if (not contributorObj['description'].is_a?(Hash)) or (not contributorObj['description'].has_key?(@primaryLang))
            msg = "Invalid author description for '" + contributerKey +
              "' in YAML in " + contributorsFilepath + "\n" +
              "Please ensure this authors description has an " +
              @primaryLang +
              " translation in the contributors.yaml"
            LogHelper.throwError(msg)
          end
        end

        if File.exist?(site.config['WFStaticSource'] + '/imgs/contributors/' + contributerKey + '.jpg')
          contributorObj['imgUrl'] = site.config['WFAbsoluteUrl'] + site.config['WFBaseUrl'] + '/imgs/contributors/' + contributerKey + '.jpg'
        else
          contributorObj['imgUrl'] = site.config['WFAbsoluteUrl'] + site.config['WFBaseUrl'] + '/imgs/contributors/' + 'no-photo.jpg'
        end
      }
    end

    # Generate translations manifest.
    def translations(site)
      rootFilepath = File.join @contentSource, @primaryLang
      filePatternPath = rootFilepath
      buildRelativeDir = '.'
      parentTree = nil
      pagesTree = {"id" => "root", "pages" => [], "subdirectories" => []}
      site.data['_context'] = pagesTree;

      # If a section to build is defined
      if ENV.has_key?('WF_BUILD_SECTION')
        filePatternPath = File.join filePatternPath, ENV['WF_BUILD_SECTION']
        buildRelativeDir = ENV['WF_BUILD_SECTION']

        newDirectory = {
          "id" => ENV['WF_BUILD_SECTION'],
          "pages" => [],
          "subdirectories" => []
        }
        pagesTree['subdirectories'] << newDirectory

        parentTree = pagesTree
        pagesTree = newDirectory
      end

      # Get files in directory
      fileEntries = Dir.entries(filePatternPath)
      site.data['primes'] = []
      allPages = []

      # handleFileEntries(allPages, parentTree, pagesTree, site, rootFilepath, buildRelativeDir, fileEntries)

      allPages
    end

    def traverseFilePath(filePatternPath, relativePath = '', currentBranch)
      fileEntries = Dir.entries(filePatternPath)

      directories = []

      fileEntries.each { |fileEntry|
        fullFilePath = File.join(filePatternPath, fileEntry)
        if File.directory?(fullFilePath)
          if !isTraversibleDirectory(fileEntry)
            next
          end

          directories << fileEntry
        else
          handleFile(currentBranch, relativePath, fileEntry, @primaryLang)
        end
      }

      directories.each{ |directoryName|
        branchNode = BranchNode.new(currentBranch, directoryName)

        traverseFilePath(
          File.join(filePatternPath, directoryName),
          File.join(relativePath, directoryName),
          branchNode
        )

        if branchNode.hasNodes()
          branchNode.sortNodes()
          currentBranch.addBranchChildNode(branchNode)
        end
      }
    end

    def isTraversibleDirectory(fileName)
      # Ignore relative file entries
      if fileName == "." || fileName == ".."
        return false
      end

      # Ignore paths starting with _
      if fileName =~ /^_/
        return false
      end

      return true
    end

    # relativePath is the path relative to the current language
    # (i.e. en/folder/test.txt will have a relative path of folder/test.txt)
    def handleFile(currentBranch, relativePath, fileName, langcode)
      # If the page is a markdown file we want to create a jekyll page
      if !(@markdownExtensions.include? File.extname(fileName))
        @site.static_files << LanguageAsset.new(@contentFilepath, relativePath, fileName)
        return
      end

      # If we are here, we have a markdown page
      leafNode = LeafNode.new(currentBranch)

      page = createPage(@site, relativePath, fileName, langcode, leafNode)
      translatedPages = getTranslatedPages(relativePath, fileName, leafNode)

      leafNode.setPages(page, translatedPages)
      currentBranch.addLeafChildNode(leafNode)
      #  page.data['_context'] = pagesTrees

      #  translated_pages = {'en' => page}
      #  page.data["translations"] = translated_pages

      #  # If published is false, don't include it in the pagesTree
      #  if (@markdownExtensions.include? File.extname(fileEntry))
      #    # If it's a markdown file, add to the page tree
      #    #if !(page['published'] == false)
      #      if page.name.start_with? ('index')
      #        pagesTrees['index'] = page
      #      else
      #        pagesTrees['pages'] << page
      #      end
      #    #end
      #  end

      @site.pages << page
      @site.pages.concat(translatedPages)
    end

    def getTranslatedPages(relativePath, fileName, leafNode)
      translatedLangcodes =  @langsAvailable.select { |translationLangCode|
        includeLanguage = true
        if translationLangCode == @primaryLang
          includeLanguage = false
        end

        includeLanguage = includeLanguage && (File.exists? File.join(@contentSource, translationLangCode, relativePath, fileName))
        includeLanguage
      }

      translatedPages = []
      translatedLangcodes.each do |langcode|
        # translationFilePath = File.join @contentSource, langcode, relativePath

        translatedPage = createPage(
          @site,
          relativePath,
          fileName,
          langcode,
          leafNode)

        # translationPage.data.merge!('is_localized' => true, 'is_localization' => true)

        # translationPage.data['_context'] = pagesTrees
        # translationPage.data['translations'] = translated_pages

        # translated_pages[languageId] = translationPage
        # site.pages << translationPage
        translatedPages << translatedPage
      end

      return translatedPages
    end

    #def handleFileEntries(allPages, treeParent, pagesTrees, site, rootPath, relativePath, fileEntries)
    #  fileEntries.each { |fileEntry|
    #    if File.directory?(File.join(rootPath, relativePath, fileEntry))
    #      # We are dealing with a directory
    #      if fileEntry =~ /^_/
    #        next
    #      end
    #      if fileEntry =~ /\/_(code|assets)/
    #        next
    #      end
    #      if fileEntry == "." || fileEntry == ".."
    #        next
    #      end
    #      newDirectory = {
    #        "id" => fileEntry,
    #        "pages" => [],
    #        "subdirectories" => []
    #      }
    #      pagesTrees['subdirectories'] << newDirectory
    #
    #      if relativePath == '.'
    #        nextRelativePath = fileEntry
    #      else
    #        nextRelativePath= File.join(relativePath, fileEntry)
    #      end
    #      handleFileEntries(
    #        allPages,
    #        pagesTrees,
    #        newDirectory,
    #        site,
    #        rootPath,
    #        nextRelativePath,
    #        Dir.entries( File.join(rootPath, nextRelativePath) )
    #        )
    #    else
    #
    #    end
    #  }
    #
    #  if pagesTrees['pages'].length == 0 &&
    #    pagesTrees['subdirectories'].length == 0 &&
    #    pagesTrees['index'].nil?
    #    treeParent['subdirectories'].delete(pagesTrees)
    #  end
    #
    #end

    # Creates a new Page which must be a class that inherits from WFPage
    def createPage(site, relative_dir, file_name, langcode, leafNode)
      # Don't process underscore files.
      if relative_dir =~ /^_/
        return nil
      end

      directories = relative_dir.split(File::SEPARATOR)
      rootFolderName = directories.size > 1 ? directories[1] : "."

      page = nil
      case rootFolderName
      when 'updates'
        page = UpdatePostPage.new(site, relative_dir, file_name, langcode, leafNode)
      when 'fundamentals'
        page = FundamentalsPage.new(site, relative_dir, file_name, langcode, leafNode)
      when 'shows'
        page = ShowsPage.new(site, relative_dir, file_name, langcode, leafNode)
      when 'tools'
        page = ToolsPage.new(site, relative_dir, file_name, langcode, leafNode)
      when 'showcase'
        page = ShowcasePage.new(site, relative_dir, file_name, langcode, leafNode)
      when 'styleguide'
        page = BasePage.new(site, relative_dir, file_name, langcode, leafNode)
      when '.'
        page = LandingPage.new(site, relative_dir, file_name, langcode, leafNode)
      when 'resources'
        page = BasePage.new(site, relative_dir, file_name, langcode, leafNode)
      else
        LogHelper.throwError("main-generator.rb: Unsure what Page to use for markdown files in the \"" +
          rootFolderName + "\" directory.")
      end

      return page
    end

    # Creates a new Asset
    #def createAsset(relative_dir, file_name)
    #  # Don't process underscore files.
    #  if relative_dir =~ /^_/
    #    LogHelper.throwError("CREATE ASSET WITH BAD DIR")
    #    return nil
    #  end
    #  @staticFiles << LanguageAsset.new(relative_dir, file_name, 'en')
    #end
  end

end
