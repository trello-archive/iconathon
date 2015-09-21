$ = require 'jquery'
{ renderable, h1, h2, h3, div, ul, li, p, img, a, span, text } = require 'teacup'

baseTemplate = renderable ->
  div '.layout', ->
    div '.layout-header', ->
      h1 'Trello Icons Demo'
    div '.layout-selections', ->
      h2 '.layout-selection-header', ->
        text 'Format and Size'
      div '.js-list-formats-and-sizes'
    div '.layout-icons.js-fill-icons'

formatAndSizeSelectionTemplate = renderable (formats, currentFormat, svgSizes, fontSizes, currentSvgSize, currentFontSize) ->
  ul '.selection', ->
    for format in formats
      if format == 'SVG'
        for size in svgSizes
          formatAndSizeSelectionItemTemplate(format, currentFormat, size, currentSvgSize, currentFontSize)
      else if format == 'Font'
        for size in fontSizes
          formatAndSizeSelectionItemTemplate(format, currentFormat, size, currentSvgSize, currentFontSize)

formatAndSizeSelectionItemTemplate = renderable (format, currentFormat, size, currentSvgSize, currentFontSize) ->
  li '.selection-item', ->
    activeClass = ''
    if format == currentFormat && (size == currentSvgSize || size == currentFontSize)
      activeClass = '.is-active'
    a ".selection-item-link.js-select-format-and-size#{activeClass}", href: '#', 'data-format': "#{format}", 'data-size': "#{size}", ->
      text "#{format} - #{size}"

iconsTemplate = renderable (weights, icons, format, currentFontSize, currentSvgSize) ->
  for weight in weights
    h2 ->
      text "#{weight} Weight"
    ul '.icons', ->
      for icon in icons
        li '.icons-item', ->
          div '.icons-item-icon-frame', ->
            if format == 'SVG'
              div '.icons-item-icon-frame-helper'
              img '.icons-item-icon-frame-image', src: "/weights/#{weight}/#{currentSvgSize}/android/ic_#{icon}_#{weight}_#{currentSvgSize}.svg"
            else if format == 'Font'
              div '.icons-item-icon-frame-helper'
              span ".icons-item-icon-frame-font.icon-#{icon}-#{weight}.icon-#{currentFontSize}.mod-#{weight}"
          span '.icons-item-name', "#{icon}"

class IconathanView
  constructor: ->
    $.getJSON "/demo/data.json", (data) =>
      @icons = data.icons
      @formats = data.formats
      @weights = data.weights
      @svgSizes = data.sizes
      @fontSizes = data.fontSizes
      @fCurrentFormat = @formats[0]
      @fCurrentSvgSize = @svgSizes[@svgSizes.length - 1]
      @fCurrentFontSize = @fontSizes[0]
      @render()
    return

  renderFormatAndSizeSelections: ->
    html = formatAndSizeSelectionTemplate(@formats, @fCurrentFormat, @svgSizes, @fontSizes, @fCurrentSvgSize, @fCurrentFontSize)
    $('.js-list-formats-and-sizes').empty().append html
    @

  renderIcons: ->
    html = iconsTemplate(@weights, @icons, @fCurrentFormat, @fCurrentFontSize, @fCurrentSvgSize)
    $('.js-fill-icons').empty().append html
    @

  render: ->
    $('body').append baseTemplate()

    @renderFormatAndSizeSelections()
    @renderIcons()

    $('.js-list-formats-and-sizes').on 'click', '.js-select-format-and-size', @selectFormatAndSize.bind(@)

    @

  selectFormatAndSize: (e) ->
    e.preventDefault()
    @fCurrentFormat = $(e.target).data("format")
    @fCurrentFontSize = $(e.target).data("size")
    @fCurrentSvgSize = $(e.target).data("size")
    @renderFormatAndSizeSelections()
    @renderIcons()
    false

module.exports = IconathanView
