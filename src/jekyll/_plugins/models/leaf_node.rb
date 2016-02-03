require File.expand_path('../node.rb', __FILE__)

class LeafNode < Node

  attr_reader :isIndexLeaf

  def initialize(parentNode)
    super(parentNode)

    @primaryLanguagePage = nil
    @translatedPages = []
    @isIndexLeaf = false
  end

  def setPages(primaryLanguagePage, translatedPages)
    @primaryLanguagePage = primaryLanguagePage
    @translatedPages = translatedPages

    @isIndexLeaf = primaryLanguagePage.name.start_with? ('index')
  end

  def getPageForLang(langcode)
    if langcode == @primaryLanguagePage.langcode
      return @primaryLanguagePage
    end

    @translatedPages.each { |translatedPage|
      if translatedPage.langcode == langcode
        return translatedPage
      end
    }

    return @primaryLanguagePage
  end
end
